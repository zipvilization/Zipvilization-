// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev Base network. DEX integration is router/pair injected at deploy (Aerodrome-compatible V2-style router).
 *
 * CORE PRINCIPLES:
 * - Fixed supply (no mint, no inflation)
 * - Reflection (dual-supply) + real burn (supply decreases)
 * - Immutable buy/sell/transfer fee rules (constants)
 * - Anti-whale protections (maxTx + dynamic maxWallet)
 * - Treasury timelock (propose/confirm)
 * - SwapBack controls (pause + cooldown + cap + best-effort slippage guard)
 * - Post-launch config freeze (Option A)
 *
 * IMPORTANT:
 * - This contract expects a V2-style router interface for swap/addLiquidity.
 * - For Aerodrome, deploy with the router that matches your pool type and supports these calls.
 * - Pair address MUST be injected correctly at deployment.
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

/**
 * @dev Minimal V2-style router interface. Many routers expose compatible signatures.
 * If your chosen router differs, adjust this interface + swap/addLiquidity functions accordingly.
 */
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

/**
 * @dev Minimal Ownable (no external deps).
 */
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

    /* ---------- TAX CONFIG (IMMUTABLE CONSTANTS) ---------- */
    // BUY: 0.5% LP + 0.5% Treasury
    uint256 public constant BUY_LP_FEE = 5_000;        // 0.5%
    uint256 public constant BUY_TREASURY_FEE = 5_000;  // 0.5%

    // SELL: 4% burn, 3% reflection, 2% LP, 1% treasury (10%)
    uint256 public constant SELL_BURN_FEE = 40_000;       // 4%
    uint256 public constant SELL_REFLECTION_FEE = 30_000; // 3%
    uint256 public constant SELL_LP_FEE = 20_000;         // 2%
    uint256 public constant SELL_TREASURY_FEE = 10_000;   // 1%

    // TRANSFER: 2% burn, 3% reflection (5%)
    uint256 public constant TRANSFER_BURN_FEE = 20_000;       // 2%
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000; // 3%

    bool public feesLocked = true; // present for compatibility / signaling

    /* ---------- LIMITS ---------- */
    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals; // 10B fixed

    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals; // 30B
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH = 110_000; // +10% weekly (1.10x)

    /* ---------- TREASURY TIMELOCK ---------- */
    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;
    uint256 public constant TREASURY_CHANGE_DELAY = 48 hours;

    /* ---------- DEX / PAIR ---------- */
    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    /* ---------- CONFIG FREEZE (OPTION A) ---------- */
    bool public configFrozen = false;
    event ConfigFrozen(uint256 timestamp);

    modifier whenConfigNotFrozen() {
        require(!configFrozen, "CONFIG_FROZEN");
        _;
    }

    function freezeConfig() external onlyOwner whenConfigNotFrozen {
        // You may choose to require(tradingEnabled) to avoid freezing too early.
        // require(tradingEnabled, "TRADING_OFF");
        configFrozen = true;
        emit ConfigFrozen(block.timestamp);
    }

    /* ---------- SWAPBACK CONTROLS ---------- */
    bool public swapBackEnabled = true;
    bool public tradingEnabled = false;

    uint256 public swapThreshold = 200_000_000 * 10**decimals;       // 200M tokens (tune pre-freeze)
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**decimals; // 1B tokens max per swap (tune pre-freeze)
    uint256 public swapBackCooldown = 60;                            // seconds (tune pre-freeze)
    uint256 public slippageBps = 300;                                // 3% (tune pre-freeze; 50..800)

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
    event SwapBackConfigUpdated(uint256 threshold, uint256 maxAmount, uint256 cooldown, uint256 slippageBps);

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
        require(_router != address(0) && _pair != address(0) && _weth != address(0) && _treasury != address(0), "ZERO_ADDR");

        router = _router;
        pair = _pair;
        weth = _weth;

        treasury = _treasury;
        deploymentTime = block.timestamp;

        // initial distribution to deployer
        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // exemptions (can be frozen later)
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[_treasury] = true;

        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[_treasury] = true;
        isLimitExempt[_router] = true;
        isLimitExempt[_pair] = true;
    }

    /* ============================== */
    /* ======= ERC20 LOGIC ========== */
    /* ============================== */

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

    /* ============================== */
    /* ========= ADMIN ============== */
    /* ============================== */

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TRADING_ON");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setSwapBackPaused(bool paused) external onlyOwner {
        // Operational safety switch is allowed even after freeze.
        swapBackEnabled = !paused;
        emit SwapBackPaused(paused);
    }

    function setSwapBackConfig(
        uint256 threshold,
        uint256 maxAmount,
        uint256 cooldownSeconds,
        uint256 newSlippageBps
    ) external onlyOwner whenConfigNotFrozen {
        // guardrails (avoid accidental DoS / extremes)
        require(newSlippageBps >= 50 && newSlippageBps <= 800, "SLIPPAGE_RANGE");
        require(maxAmount >= threshold, "MAX_LT_THRESHOLD");
        require(cooldownSeconds <= 15 minutes, "COOLDOWN_TOO_HIGH");

        swapThreshold = threshold;
        swapBackMaxAmount = maxAmount;
        swapBackCooldown = cooldownSeconds;
        slippageBps = newSlippageBps;

        emit SwapBackConfigUpdated(threshold, maxAmount, cooldownSeconds, newSlippageBps);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner whenConfigNotFrozen {
        isFeeExempt[account] = exempt;
    }

    function setLimitExempt(address account, bool exempt) external onlyOwner whenConfigNotFrozen {
        isLimitExempt[account] = exempt;
    }

    /* ---------- Treasury timelock ---------- */

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

        // keep exemptions aligned (may be frozen already; but treasury change is protected by timelock)
        isFeeExempt[treasury] = true;
        isLimitExempt[treasury] = true;

        emit TreasuryConfirmed(treasury);
    }

    /* ============================== */
    /* ========= INTERNALS ========== */
    /* ============================== */

    function reflectionFromToken(uint256 tAmount) public view returns (uint256) {
        require(tAmount <= _tTotal, "AMOUNT_GT_SUPPLY");
        uint256 currentRate = _getRate();
        return tAmount * currentRate;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "R_GT_TOTAL");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _getRate() internal view returns (uint256) {
        return _rTotal / _tTotal;
    }

    function _maxWalletNow() internal view returns (uint256) {
        if (block.timestamp < deploymentTime + MAX_WALLET_GROWTH_DELAY) {
            return MAX_WALLET_INITIAL;
        }

        uint256 weeksElapsed = (block.timestamp - (deploymentTime + MAX_WALLET_GROWTH_DELAY)) / 1 weeks;
        uint256 limit = MAX_WALLET_INITIAL;

        // cap loop cost (~10 years). After that treat as effectively uncapped.
        if (weeksElapsed > 520) {
            return type(uint256).max;
        }

        for (uint256 i = 0; i < weeksElapsed; i++) {
            // +10% weekly: limit *= 1.10
            limit = (limit * MAX_WALLET_WEEKLY_GROWTH) / 100_000;
        }

        return limit;
    }

    function _shouldSwapBack(address /*from*/, address to) internal view returns (bool) {
        if (!swapBackEnabled) return false;
        if (_inSwapBack) return false;
        if (!tradingEnabled) return false;

        // Trigger primarily on sells to reduce random timing.
        bool isSell = (to == pair);
        if (!isSell) return false;

        if (block.timestamp < lastSwapBackTime + swapBackCooldown) return false;

        uint256 contractTokenBalance = balanceOf(address(this));
        return contractTokenBalance >= swapThreshold;
    }

    function _transfer(address from, address to, uint256 tAmount) internal {
        require(from != address(0) && to != address(0), "ZERO_ADDR");
        require(tAmount > 0, "ZERO_AMOUNT");

        // Pre-trading: only exempt addresses can move
        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        // Limits: maxTx
        if (!isLimitExempt[from] && !isLimitExempt[to]) {
            require(tAmount <= MAX_TX_AMOUNT, "MAX_TX");
        }

        // SwapBack before applying this sell (best-effort, caps apply)
        if (_shouldSwapBack(from, to)) {
            _swapBack();
        }

        // Determine tx type
        bool isBuy = (from == pair);
        bool isSell = (to == pair);

        bool takeFee = !_inSwapBack && !(isFeeExempt[from] || isFeeExempt[to]);

        // Wallet limit (only on receive; ignore pair/router/contract/treasury/exempt)
        if (!isLimitExempt[to] && to != pair && to != router) {
            uint256 newBal = balanceOf(to) + tAmount;
            require(newBal <= _maxWalletNow(), "MAX_WALLET");
        }

        uint256 currentRate = _getRate();

        // Convert to reflected amounts
        uint256 rAmount = tAmount * currentRate;

        // Fees in token units
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

        uint256 tFeeTotal = tBurn + tReflection + tLP + tTreasury;
        uint256 tTransferAmount = tAmount - tFeeTotal;

        uint256 rBurn = tBurn * currentRate;
        uint256 rReflection = tReflection * currentRate;
        uint256 rLP = tLP * currentRate;
        uint256 rTreasury = tTreasury * currentRate;
        uint256 rTransferAmount = tTransferAmount * currentRate;

        // Deduct from sender
        require(_rOwned[from] >= rAmount, "BALANCE");
        _rOwned[from] -= rAmount;

        // Credit recipient
        _rOwned[to] += rTransferAmount;

        emit Transfer(from, to, tTransferAmount);

        // LP + Treasury fee: collected to contract (later swapBack)
        uint256 rToContract = rLP + rTreasury;
        if (rToContract > 0) {
            _rOwned[address(this)] += rToContract;
            emit Transfer(from, address(this), tLP + tTreasury);
        }

        // Reflection: reduce rTotal (standard reflect mechanic)
        if (rReflection > 0) {
            _rTotal -= rReflection;
        }

        // Real burn: reduce both totals to keep rate consistent
        if (tBurn > 0) {
            _tTotal -= tBurn;
            _rTotal -= rBurn;
            emit Transfer(from, address(0), tBurn);
        }
    }

    /* ============================== */
    /* ========= SWAPBACK =========== */
    /* ============================== */

    function _swapBack() internal lockTheSwap {
        lastSwapBackTime = block.timestamp;

        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance < swapThreshold) return;

        uint256 amountToProcess = contractTokenBalance;
        if (amountToProcess > swapBackMaxAmount) amountToProcess = swapBackMaxAmount;

        // Conservative split:
        // - 25% of processed tokens paired with ETH for liquidity
        // - 75% swapped for ETH, then ETH split 50/50 (liquidity/treasury)
        uint256 tokensForLiquidity = amountToProcess / 4;
        uint256 tokensToSwapForETH = amountToProcess - tokensForLiquidity;

        // Approve router for the exact amount used.
        _approveInternal(address(this), router, amountToProcess);

        uint256 ethBefore = address(this).balance;

        // Swap tokensToSwapForETH for ETH, best-effort minOut.
        uint256 minOut = _computeMinOut(tokensToSwapForETH);
        _swapTokensForETH(tokensToSwapForETH, minOut);

        uint256 ethGained = address(this).balance - ethBefore;
        if (ethGained == 0) return;

        uint256 ethForLiquidity = ethGained / 2;
        uint256 ethForTreasury = ethGained - ethForLiquidity;

        // Add liquidity (mins set to 0 to avoid revert/DoS; protected by cap+cooldown+minOut on swap)
        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(tokensForLiquidity, ethForLiquidity);
        }

        // Treasury payout
        if (ethForTreasury > 0) {
            (bool ok, ) = treasury.call{value: ethForTreasury}("");
            require(ok, "TREASURY_SEND_FAIL");
        }
    }

    function _computeMinOut(uint256 amountIn) internal view returns (uint256) {
        // Best-effort: try router.getAmountsOut; if unavailable, return 0 (still protected by cap+cooldown).
        address;
        path[0] = address(this);
        path[1] = weth;

        try IDexV2Router(router).getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            if (amounts.length < 2) return 0;
            uint256 expectedOut = amounts[amounts.length - 1];
            if (expectedOut == 0) return 0;

            uint256 bps = slippageBps;
            return (expectedOut * (10_000 - bps)) / 10_000;
        } catch {
            return 0;
        }
    }

    function _swapTokensForETH(uint256 tokenAmount, uint256 amountOutMin) internal {
        address;
        path[0] = address(this);
        path[1] = weth;

        IDexV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin,
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
