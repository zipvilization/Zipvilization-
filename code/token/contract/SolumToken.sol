// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev Base network. DEX integration is router/pair injected at deploy (V2-style router).
 *
 * CORE PRINCIPLES:
 * - Fixed supply (no mint, no inflation)
 * - Reflection (dual-supply) + real burn
 * - Immutable fee rules (constants)
 * - Anti-whale protections
 * - Treasury timelock
 * - SwapBack with caps + cooldown
 * - Post-launch config freeze (Option A)
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
    /* ---------- METADATA ---------- */
    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    /* ---------- SUPPLY (DUAL) ---------- */
    uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    /* ---------- FEE DENOM ---------- */
    uint256 private constant FEE_DENOM = 1_000_000;

    /* ---------- TAX CONFIG ---------- */
    uint256 public constant BUY_LP_FEE = 5_000;
    uint256 public constant BUY_TREASURY_FEE = 5_000;

    uint256 public constant SELL_BURN_FEE = 40_000;
    uint256 public constant SELL_REFLECTION_FEE = 30_000;
    uint256 public constant SELL_LP_FEE = 20_000;
    uint256 public constant SELL_TREASURY_FEE = 10_000;

    uint256 public constant TRANSFER_BURN_FEE = 20_000;
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000;

    bool public feesLocked = true;

    /* ---------- LIMITS ---------- */
    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals;

    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals;
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH = 110_000;

    /* ---------- TREASURY ---------- */
    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;
    uint256 public constant TREASURY_CHANGE_DELAY = 48 hours;

    /* ---------- DEX ---------- */
    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    /* ---------- CONFIG FREEZE ---------- */
    bool public configFrozen = false;
    event ConfigFrozen(uint256 timestamp);

    modifier whenConfigNotFrozen() {
        require(!configFrozen, "CONFIG_FROZEN");
        _;
    }

    function freezeConfig() external onlyOwner whenConfigNotFrozen {
        configFrozen = true;
        emit ConfigFrozen(block.timestamp);
    }

    /* ---------- SWAPBACK ---------- */
    bool public tradingEnabled = false;
    bool public swapBackEnabled = true;

    uint256 public swapThreshold = 200_000_000 * 10**decimals;
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**decimals;
    uint256 public swapBackCooldown = 60;
    uint256 public slippageBps = 300;

    uint256 public lastSwapBackTime;
    bool private _inSwapBack;

    /* ---------- STATE ---------- */
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExempt;

    uint256 public immutable deploymentTime;

    /* ---------- EVENTS ---------- */
    event TradingEnabled();
    event SwapBackPaused(bool paused);
    event TreasuryProposed(address indexed newTreasury, uint256 availableAt);
    event TreasuryConfirmed(address indexed newTreasury);

    modifier lockTheSwap() {
        _inSwapBack = true;
        _;
        _inSwapBack = false;
    }

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
        pair = _pair;
        weth = _weth;
        treasury = _treasury;
        deploymentTime = block.timestamp;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[_treasury] = true;

        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[_treasury] = true;
        isLimitExempt[_router] = true;
        isLimitExempt[_pair] = true;
    }

    /* ---------- ERC20 ---------- */

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ALLOWANCE");
        _allowances[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }

    /* ---------- ADMIN ---------- */

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TRADING_ON");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setSwapBackPaused(bool paused) external onlyOwner {
        swapBackEnabled = !paused;
        emit SwapBackPaused(paused);
    }

    function setSwapBackConfig(
        uint256 threshold,
        uint256 maxAmount,
        uint256 cooldownSeconds,
        uint256 newSlippageBps
    ) external onlyOwner whenConfigNotFrozen {
        require(newSlippageBps >= 50 && newSlippageBps <= 800, "SLIPPAGE_RANGE");
        require(maxAmount >= threshold, "MAX_LT_THRESHOLD");
        require(cooldownSeconds <= 15 minutes, "COOLDOWN_HIGH");

        swapThreshold = threshold;
        swapBackMaxAmount = maxAmount;
        swapBackCooldown = cooldownSeconds;
        slippageBps = newSlippageBps;
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner whenConfigNotFrozen {
        isFeeExempt[account] = exempt;
    }

    function setLimitExempt(address account, bool exempt) external onlyOwner whenConfigNotFrozen {
        isLimitExempt[account] = exempt;
    }

    function proposeTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "ZERO_ADDR");
        pendingTreasury = newTreasury;
        treasuryChangeTime = block.timestamp + TREASURY_CHANGE_DELAY;
        emit TreasuryProposed(newTreasury, treasuryChangeTime);
    }

    function confirmTreasury() external onlyOwner {
        require(pendingTreasury != address(0), "NO_PENDING");
        require(block.timestamp >= treasuryChangeTime, "TIMELOCK");
        treasury = pendingTreasury;
        pendingTreasury = address(0);
        treasuryChangeTime = 0;
        isFeeExempt[treasury] = true;
        isLimitExempt[treasury] = true;
        emit TreasuryConfirmed(treasury);
    }

    /* ---------- INTERNAL ---------- */

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        uint256 rate = _rTotal / _tTotal;
        return rAmount / rate;
    }

    function _maxWalletNow() internal view returns (uint256) {
        if (block.timestamp < deploymentTime + MAX_WALLET_GROWTH_DELAY) {
            return MAX_WALLET_INITIAL;
        }

        uint256 weeksElapsed =
            (block.timestamp - (deploymentTime + MAX_WALLET_GROWTH_DELAY)) / 1 weeks;

        if (weeksElapsed > 520) return type(uint256).max;

        uint256 limit = MAX_WALLET_INITIAL;
        for (uint256 i = 0; i < weeksElapsed; i++) {
            limit = (limit * MAX_WALLET_WEEKLY_GROWTH) / 100_000;
        }
        return limit;
    }

    function _shouldSwapBack(address to) internal view returns (bool) {
        if (!swapBackEnabled || _inSwapBack || !tradingEnabled) return false;
        if (to != pair) return false;
        if (block.timestamp < lastSwapBackTime + swapBackCooldown) return false;
        return balanceOf(address(this)) >= swapThreshold;
    }

    function _transfer(address from, address to, uint256 tAmount) internal {
        require(from != address(0) && to != address(0), "ZERO_ADDR");
        require(tAmount > 0, "ZERO_AMOUNT");

        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        if (!isLimitExempt[from] && !isLimitExempt[to]) {
            require(tAmount <= MAX_TX_AMOUNT, "MAX_TX");
        }

        if (_shouldSwapBack(to)) {
            _swapBack();
        }

        if (!isLimitExempt[to] && to != pair && to != router) {
            require(balanceOf(to) + tAmount <= _maxWalletNow(), "MAX_WALLET");
        }

        uint256 rate = _rTotal / _tTotal;
        uint256 rAmount = tAmount * rate;

        bool isBuy = (from == pair);
        bool isSell = (to == pair);
        bool takeFee = !_inSwapBack && !(isFeeExempt[from] || isFeeExempt[to]);

        uint256 tBurn;
        uint256 tReflection;
        uint256 tLP;
        uint256 tTreasury;

        if (takeFee) {
            if (isBuy) {
                tLP = (tAmount * BUY_LP_FEE) / FEE_DENOM;
                tTreasury = (tAmount * BUY_TREASURY_FEE) / FEE_DENOM;
            } else if (isSell) {
                tBurn = (tAmount * SELL_BURN_FEE) / FEE_DENOM;
                tReflection = (tAmount * SELL_REFLECTION_FEE) / FEE_DENOM;
                tLP = (tAmount * SELL_LP_FEE) / FEE_DENOM;
                tTreasury = (tAmount * SELL_TREASURY_FEE) / FEE_DENOM;
            } else {
                tBurn = (tAmount * TRANSFER_BURN_FEE) / FEE_DENOM;
                tReflection = (tAmount * TRANSFER_REFLECTION_FEE) / FEE_DENOM;
            }
        }

        uint256 tFee = tBurn + tReflection + tLP + tTreasury;
        uint256 tTransfer = tAmount - tFee;

        _rOwned[from] -= rAmount;
        _rOwned[to] += tTransfer * rate;
        emit Transfer(from, to, tTransfer);

        if (tLP + tTreasury > 0) {
            _rOwned[address(this)] += (tLP + tTreasury) * rate;
            emit Transfer(from, address(this), tLP + tTreasury);
        }

        if (tReflection > 0) {
            _rTotal -= tReflection * rate;
        }

        if (tBurn > 0) {
            _tTotal -= tBurn;
            _rTotal -= tBurn * rate;
            emit Transfer(from, address(0), tBurn);
        }
    }

    function _swapBack() internal lockTheSwap {
        lastSwapBackTime = block.timestamp;

        uint256 contractTokens = balanceOf(address(this));
        uint256 amount = contractTokens > swapBackMaxAmount
            ? swapBackMaxAmount
            : contractTokens;

        uint256 tokensForLiquidity = amount / 4;
        uint256 tokensToSwap = amount - tokensForLiquidity;

        _approveInternal(address(this), router, amount);

        uint256 ethBefore = address(this).balance;

        uint256 minOut = _computeMinOut(tokensToSwap);
        _swapTokensForETH(tokensToSwap, minOut);

        uint256 ethGained = address(this).balance - ethBefore;
        if (ethGained == 0) return;

        uint256 ethForLiquidity = ethGained / 2;
        uint256 ethForTreasury = ethGained - ethForLiquidity;

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(tokensForLiquidity, ethForLiquidity);
        }

        if (ethForTreasury > 0) {
            (bool ok, ) = treasury.call{value: ethForTreasury}("");
            require(ok, "TREASURY_SEND_FAIL");
        }
    }

    function _computeMinOut(uint256 amountIn) internal view returns (uint256) {
        address;
        path[0] = address(this);
        path[1] = weth;

        try IDexV2Router(router).getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            if (amounts.length < 2) return 0;
            uint256 expected = amounts[1];
            return (expected * (10_000 - slippageBps)) / 10_000;
        } catch {
            return 0;
        }
    }

    function _swapTokensForETH(uint256 amount, uint256 minOut) internal {
        address;
        path[0] = address(this);
        path[1] = weth;

        IDexV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        IDexV2Router(router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner,
            block.timestamp
        );
    }

    function _approveInternal(address owner_, address spender, uint256 amount) internal {
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    receive() external payable {}
}
