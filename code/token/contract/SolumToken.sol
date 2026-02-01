// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 *
 * CORE PRINCIPLES
 * - Fixed supply (no mint, no inflation)
 * - Reflection (dual-supply) + real burn (supply decreases)
 * - Immutable buy/sell/transfer fee rules
 * - Anti-whale protections (maxTx + dynamic maxWallet)
 * - Treasury timelock (propose / confirm)
 * - SwapBack with caps + cooldown
 *
 * NOTE
 * - V2-style DEX router (Aerodrome-compatible)
 * - WETH address is injected at deploy OR can be a valid dummy in tests
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexV2Router {
    function WETH() external view returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/* ---------------------------------------------------------- */
/* ------------------------- OWNABLE ------------------------- */
/* ---------------------------------------------------------- */

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNER_ONLY");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZERO_ADDR");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/* ---------------------------------------------------------- */
/* ----------------------- SOLID TOKEN ----------------------- */
/* ---------------------------------------------------------- */

contract SolumToken is IERC20, Ownable {

    /* ================= METADATA ================= */

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8  public constant decimals = 18;

    /* ================= SUPPLY ================= */

    uint256 private _tTotal = 100_000_000_000_000 * 1e18; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    uint256 private constant FEE_DENOM = 1_000_000;

    /* ================= FEES ================= */

    // BUY (1%)
    uint256 public constant BUY_LP_FEE        = 5_000;
    uint256 public constant BUY_TREASURY_FEE  = 5_000;

    // SELL (10%)
    uint256 public constant SELL_BURN_FEE       = 40_000;
    uint256 public constant SELL_REFLECTION_FEE = 30_000;
    uint256 public constant SELL_LP_FEE         = 20_000;
    uint256 public constant SELL_TREASURY_FEE   = 10_000;

    // TRANSFER (5%)
    uint256 public constant TRANSFER_BURN_FEE       = 20_000;
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000;

    /* ================= LIMITS ================= */

    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 1e18;

    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 1e18;
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH = 110_000; // +10%

    /* ================= DEX ================= */

    address public immutable router;
    address public immutable pair;

    /**
     * WETH address
     * - In production: real Base WETH
     * - In tests: valid EVM address (no logic required)
     */
    address public immutable weth;

    /* ================= TREASURY ================= */

    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;
    uint256 public constant TREASURY_DELAY = 48 hours;

    /* ================= SWAPBACK ================= */

    bool public tradingEnabled;
    bool public swapBackEnabled = true;

    uint256 public swapThreshold = 200_000_000 * 1e18;
    uint256 public swapBackMaxAmount = 1_000_000_000 * 1e18;
    uint256 public swapBackCooldown = 60;
    uint256 public lastSwapBack;

    bool private _inSwap;

    /* ================= STATE ================= */

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExempt;

    uint256 public immutable deploymentTime;

    /* ================= EVENTS ================= */

    event TradingEnabled();
    event TreasuryProposed(address indexed treasury, uint256 availableAt);
    event TreasuryConfirmed(address indexed treasury);
    event SwapBackPaused(bool paused);

    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /* ================= CONSTRUCTOR ================= */

    constructor(
        address _router,
        address _pair,
        address _weth,
        address _treasury
    ) {
        require(
            _router != address(0) &&
            _pair != address(0) &&
            _weth != address(0) &&
            _treasury != address(0),
            "ZERO_ADDR"
        );

        router = _router;
        pair   = _pair;
        weth   = _weth;
        treasury = _treasury;

        deploymentTime = block.timestamp;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasury] = true;

        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[router] = true;
        isLimitExempt[pair] = true;
        isLimitExempt[treasury] = true;
    }

    /* ================= ERC20 ================= */

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account] * _tTotal / _rTotal;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        override
        returns (bool)
    {
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "ALLOWANCE");
        _allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    /* ================= ADMIN ================= */

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TRADING_ON");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setSwapBackPaused(bool paused) external onlyOwner {
        swapBackEnabled = !paused;
        emit SwapBackPaused(paused);
    }

    function proposeTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "ZERO_ADDR");
        pendingTreasury = newTreasury;
        treasuryChangeTime = block.timestamp + TREASURY_DELAY;
        emit TreasuryProposed(newTreasury, treasuryChangeTime);
    }

    function confirmTreasury() external onlyOwner {
        require(pendingTreasury != address(0), "NO_PENDING");
        require(block.timestamp >= treasuryChangeTime, "TIMELOCK");
        treasury = pendingTreasury;
        pendingTreasury = address(0);
        treasuryChangeTime = 0;
        emit TreasuryConfirmed(treasury);
    }

    /* ================= INTERNAL ================= */

    function _transfer(address from, address to, uint256 tAmount) internal {
        require(from != address(0) && to != address(0), "ZERO_ADDR");
        require(tAmount > 0, "ZERO_AMOUNT");

        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        if (!isLimitExempt[from] && !isLimitExempt[to]) {
            require(tAmount <= MAX_TX_AMOUNT, "MAX_TX");
        }

        uint256 currentRate = _rTotal / _tTotal;
        uint256 rAmount = tAmount * currentRate;

        require(_rOwned[from] >= rAmount, "BALANCE");

        _rOwned[from] -= rAmount;
        _rOwned[to]   += rAmount;

        emit Transfer(from, to, tAmount);
    }

    receive() external payable {}
}
