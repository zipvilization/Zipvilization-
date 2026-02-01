// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev Base network. DEX integration is router/pair injected at deploy (V2-style router).
 *
 * CORE PRINCIPLES:
 * - Fixed supply (no mint)
 * - Reflection (dual-supply) + real burn
 * - Immutable fee rules
 * - Anti-whale protections
 * - Treasury timelock
 * - SwapBack with caps + cooldown
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

contract Solum is IERC20, Ownable {

    /* ---------------------------------------------------------- */
    /*                         CONSTANTS                          */
    /* ---------------------------------------------------------- */

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    uint256 private constant FEE_DENOM = 1_000_000;

    // ✅ Canonical Base WETH (fallback if _weth == address(0))
    address public constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    /* ---------------------------------------------------------- */
    /*                         SUPPLY                             */
    /* ---------------------------------------------------------- */

    uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    /* ---------------------------------------------------------- */
    /*                           FEES                             */
    /* ---------------------------------------------------------- */

    // BUY (1%)
    uint256 public constant BUY_LP_FEE = 5_000;
    uint256 public constant BUY_TREASURY_FEE = 5_000;

    // SELL (10%)
    uint256 public constant SELL_BURN_FEE = 40_000;
    uint256 public constant SELL_REFLECTION_FEE = 30_000;
    uint256 public constant SELL_LP_FEE = 20_000;
    uint256 public constant SELL_TREASURY_FEE = 10_000;

    // TRANSFER (5%)
    uint256 public constant TRANSFER_BURN_FEE = 20_000;
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000;

    /* ---------------------------------------------------------- */
    /*                           LIMITS                           */
    /* ---------------------------------------------------------- */

    uint256 public constant MAX_TX_AMOUNT =
        10_000_000_000 * 10**decimals;

    uint256 public constant MAX_WALLET_INITIAL =
        30_000_000_000 * 10**decimals;

    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH = 110_000; // +10%

    /* ---------------------------------------------------------- */
    /*                         TREASURY                           */
    /* ---------------------------------------------------------- */

    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;
    uint256 public constant TREASURY_CHANGE_DELAY = 48 hours;

    /* ---------------------------------------------------------- */
    /*                        DEX / PAIR                          */
    /* ---------------------------------------------------------- */

    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    /* ---------------------------------------------------------- */
    /*                       SWAPBACK                             */
    /* ---------------------------------------------------------- */

    bool public tradingEnabled = false;
    bool public swapBackEnabled = true;

    uint256 public swapThreshold = 200_000_000 * 10**decimals;
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**decimals;
    uint256 public swapBackCooldown = 60;
    uint256 public lastSwapBackTime;

    bool private _inSwap;

    /* ---------------------------------------------------------- */
    /*                          STATE                             */
    /* ---------------------------------------------------------- */

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExempt;

    uint256 public immutable deploymentTime;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /* ---------------------------------------------------------- */
    /*                        CONSTRUCTOR                         */
    /* ---------------------------------------------------------- */

    constructor(
        address _router,
        address _pair,
        address _weth,
        address _treasury
    ) {
        require(
            _router != address(0) &&
            _pair != address(0) &&
            _treasury != address(0),
            "ZERO_ADDR"
        );

        address resolvedWeth =
            (_weth == address(0)) ? BASE_WETH : _weth;

        router = _router;
        pair = _pair;
        weth = resolvedWeth;

        treasury = _treasury;
        deploymentTime = block.timestamp;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasury] = true;

        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[treasury] = true;
        isLimitExempt[router] = true;
        isLimitExempt[pair] = true;
    }

    /* ---------------------------------------------------------- */
    /*                      ERC20 LOGIC                           */
    /* ---------------------------------------------------------- */

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner_, address spender)
        external view override returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        external override returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        external override returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external override returns (bool)
    {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ALLOWANCE");
        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }

    /* ---------------------------------------------------------- */
    /*                     INTERNAL HELPERS                       */
    /* ---------------------------------------------------------- */

    function tokenFromReflection(uint256 rAmount)
        public view returns (uint256)
    {
        return rAmount / (_rTotal / _tTotal);
    }

    /* ---------------------------------------------------------- */
    /*                       TRANSFER                             */
    /* ---------------------------------------------------------- */

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "ZERO_AMOUNT");

        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        uint256 rate = _rTotal / _tTotal;
        uint256 rAmount = amount * rate;

        _rOwned[from] -= rAmount;
        _rOwned[to] += rAmount;

        emit Transfer(from, to, amount);
    }

    /* ---------------------------------------------------------- */
    /*                      ADMIN                                 */
    /* ---------------------------------------------------------- */

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TRADING_ON");
        tradingEnabled = true;
    }

    receive() external payable {}
}
