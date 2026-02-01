// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev Base network. Router/Pair/WETH are injected at deploy (V2-style router, Aerodrome-compatible).
 *
 * CANONICAL CORE (FULL)
 * - Fixed supply (no mint)
 * - Reflection (dual-supply) + real burn (supply decreases)
 * - Immutable buy/sell/transfer fee rules (constants)
 * - Anti-whale: maxTx (fixed) + maxWallet (dynamic growth after delay)
 * - Treasury timelock: propose / confirm with delay
 * - SwapBack controls: pause + cooldown + cap + best-effort slippage guard
 *
 * IMPORTANT
 * - No references to any external project names/lore. This repo is Zipvilization-only.
 * - If a rule is not in this contract, it does not exist on-chain.
 */

/* ============================== */
/* ======== INTERFACES ========== */
/* ============================== */

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

/* ============================== */
/* ============ OWNABLE ========= */
/* ============================== */

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

/* ============================== */
/* ========== CONTRACT ========== */
/* ============================== */

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
    // BUY: 0.5% LP + 0.5% Treasury (1%)
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

    /* ---------- LIMITS ---------- */

    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals; // 10B fixed

    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals; // 30B
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH_PPM = 110_000; // +10% weekly, ppm base 100_000

    /* ---------- TREASURY TIMELOCK ---------- */

    address public treasury;
    address public pendingTreasury;
    uint256 public treasuryChangeTime;
    uint256 public constant TREASURY_CHANGE_DELAY = 48 hours;

    /* ---------- DEX / PAIR ---------- */

    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    /* ---------- SWAPBACK CONTROLS ---------- */

    bool public tradingEnabled = false;
    bool public swapBackEnabled = true;

    uint256 public swapThreshold = 200_000_000 * 10**decimals;       // 200M
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**decimals; // 1B
    uint256 public swapBackCooldown = 60; // seconds
    uint256 public slippageBps = 300; // 3% (basis points)

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
    event FeeExemptSet(address indexed account, bool exempt);
    event LimitExemptSet(address indexed account, bool exempt);

    modifier lockTheSwap() {
        _inSwapBack = true;
        _;
        _inSwapBack = false;
    }

    /* ============================== */
    /* ========= CONSTRUCTOR ======== */
    /* ============================== */

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

        // exemptions
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
        _approveInternal(msg.sender, spender, amount);
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
        swapBackEnabled = !paused;
        emit SwapBackPaused(paused);
    }

    function setSwapBackConfig(
        uint256 threshold,
        uint256 maxAmount,
        uint256 cooldownSeconds,
        uint256 newSlippageBps
    ) external onlyOwner {
        // guardrails
        require(newSlippageBps >= 50 && newSlippageBps <= 800, "SLIPPAGE_RANGE");
        require(maxAmount >= threshold, "MAX_LT_THRESHOLD");
        require(cooldownSeconds <= 15 minutes, "COOLDOWN_TOO_HIGH");

        swapThreshold = threshold;
        swapBackMaxAmount = maxAmount;
        swapBackCooldown = cooldownSeconds;
        slippageBps = newSlippageBps;

        emit SwapBackConfigUpdated(threshold, maxAmount, cooldownSeconds, newSlippageBps);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
        emit FeeExemptSet(account, exempt);
    }

    function setLimitExempt(address account, bool exempt) external onlyOwner {
        isLimitExempt[account] = exempt;
        emit LimitExemptSet(account, exempt);
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

        // keep exemptions aligned
        isFeeExempt[treasury] = true;
        isLimitExempt[treasury] = true;

        emit TreasuryConfirmed(treasury);
    }

    /* ============================== */
    /* ========= REFLECTION ========= */
    /* ============================== */

    function _getRate() internal view returns (uint256) {
        // _tTotal can only decrease via real burn; rate stays well-defined
        return _rTotal / _tTotal;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        uint256 rate = _getRate();
        return rAmount / rate;
    }

    function reflectionFromToken(uint256 tAmount) public view returns (uint256) {
        uint256 rate = _getRate();
        return tAmount * rate;
    }

    /* ============================== */
    /* ========= LIMITS ============= */
    /* ============================== */

    function _maxWalletNow() internal view returns (uint256) {
        if (block.timestamp < deploymentTime + MAX_WALLET_GROWTH_DELAY) {
            return MAX_WALLET_INITIAL;
        }

        uint256 weeksElapsed = (block.timestamp - (deploymentTime + MAX_WALLET_GROWTH_DELAY)) / 1 weeks;

        // cap loop cost: if called years later, avoid pathological gas
        if (weeksElapsed > 520) {
            return type(uint256).max;
        }

        uint256 limit = MAX_WALLET_INITIAL;
        for (uint256 i = 0; i < weeksElapsed; i++) {
            // limit *= 1.10 (ppm base 100_000)
            limit = (limit * MAX_WALLET_WEEKLY_GROWTH_PPM) / 100_000;
        }
        return limit;
    }

    /* ============================== */
    /* ========= SWAPBACK =========== */
    /* ============================== */

    function _shouldSwapBack(address from, address to) internal view returns (bool) {
        if (!swapBackEnabled) return false;
        if (_inSwapBack) return false;
        if (!tradingEnabled) return false;

        // Trigger primarily on sells
        bool isSell = (to == pair);
        if (!isSell) return false;

        if (block.timestamp < lastSwapBackTime + swapBackCooldown) return false;

        uint256 contractTokenBalance = tokenFromReflection(_rOwned[address(this)]);
        return contractTokenBalance >= swapThreshold;
    }

    function _computeMinOut(uint256 amountIn) internal view returns (uint256) {
        address;
        path[0] = address(this);
        path[1] = weth;

        // Best-effort: use getAmountsOut if router supports it; otherwise return 0.
        try IDexV2Router(router).getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            if (amounts.length == 0) return 0;
            uint256 out = amounts[amounts.length - 1];
            // Apply slippageBps (basis points, 10_000 = 100%)
            return (out * (10_000 - slippageBps)) / 10_000;
        } catch {
            return 0;
        }
    }

    function _swapTokensForETH(uint256 tokenAmount, uint256 minOut) internal {
        address;
        path[0] = address(this);
        path[1] = weth;

        IDexV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve already set for router
        IDexV2Router(router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner, // LP tokens to owner (can be a locker/multisig off-chain)
            block.timestamp
        );
    }

    function _swapBack() internal lockTheSwap {
        lastSwapBackTime = block.timestamp;

        uint256 contractTokenBalance = tokenFromReflection(_rOwned[address(this)]);
        if (contractTokenBalance < swapThreshold) return;

        uint256 amountToProcess = contractTokenBalance;
        if (amountToProcess > swapBackMaxAmount) amountToProcess = swapBackMaxAmount;

        // Conservative split:
        // - 25% kept as tokens for liquidity (paired with ETH)
        // - 75% swapped to ETH
        uint256 tokensForLiquidity = amountToProcess / 4;
        uint256 tokensToSwapForETH = amountToProcess - tokensForLiquidity;

        // Ensure contract has enough reflected balance
        uint256 rate = _getRate();
        uint256 rTotalNeeded = (tokensForLiquidity + tokensToSwapForETH) * rate;
        require(_rOwned[address(this)] >= rTotalNeeded, "CONTRACT_BAL");

        // Deduct reflected tokens from contract BEFORE external calls (reentrancy hygiene)
        _rOwned[address(this)] -= rTotalNeeded;

        // Approve router to pull tokens
        _approveInternal(address(this), router, tokensForLiquidity + tokensToSwapForETH);

        uint256 ethBefore = address(this).balance;

        // Swap tokensToSwapForETH for ETH (best-effort minOut)
        uint256 minOut = _computeMinOut(tokensToSwapForETH);
        _swapTokensForETH(tokensToSwapForETH, minOut);

        uint256 ethGained = address(this).balance - ethBefore;

        // If swap produced no ETH (e.g., in tests/mocks), just restore the deducted liquidity tokens and exit safely.
        if (ethGained == 0) {
            // restore liquidity tokens back to contract reflected balance
            _rOwned[address(this)] += tokensForLiquidity * rate;
            return;
        }

        // Split ETH: 50% liquidity, 50% treasury
        uint256 ethForLiquidity = ethGained / 2;
        uint256 ethForTreasury = ethGained - ethForLiquidity;

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(tokensForLiquidity, ethForLiquidity);
        } else {
            // restore liquidity tokens if we can't add liquidity
            _rOwned[address(this)] += tokensForLiquidity * rate;
        }

        if (ethForTreasury > 0) {
            (bool ok, ) = treasury.call{value: ethForTreasury}("");
            require(ok, "TREASURY_SEND_FAIL");
        }
    }

    /* ============================== */
    /* ========= TRANSFER =========== */
    /* ============================== */

    function _transfer(address from, address to, uint256 tAmount) internal {
        require(from != address(0) && to != address(0), "ZERO_ADDR");
        require(tAmount > 0, "ZERO_AMOUNT");

        // Pre-trading: only transfers involving an exempt address
        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        // Limits: maxTx
        if (!isLimitExempt[from] && !isLimitExempt[to]) {
            require(tAmount <= MAX_TX_AMOUNT, "MAX_TX");
        }

        // SwapBack before applying this sell (best-effort)
        if (_shouldSwapBack(from, to)) {
            _swapBack();
        }

        // Determine tx type
        bool isBuy = (from == pair);
        bool isSell = (to == pair);

        bool takeFee = !_inSwapBack && !(isFeeExempt[from] || isFeeExempt[to]);

        // Wallet limit (only on receive; ignore pair/router)
        if (!isLimitExempt[to] && to != pair && to != router) {
            uint256 newBal = balanceOf(to) + tAmount;
            require(newBal <= _maxWalletNow(), "MAX_WALLET");
        }

        uint256 rate = _getRate();

        // Convert to reflected amounts
        uint256 rAmount = tAmount * rate;

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

        uint256 rBurn = tBurn * rate;
        uint256 rReflection = tReflection * rate;
        uint256 rLP = tLP * rate;
        uint256 rTreasury = tTreasury * rate;
        uint256 rTransferAmount = tTransferAmount * rate;

        // Deduct from sender
        require(_rOwned[from] >= rAmount, "BALANCE");
        _rOwned[from] -= rAmount;

        // Credit recipient
        _rOwned[to] += rTransferAmount;
        emit Transfer(from, to, tTransferAmount);

        // LP + Treasury fee: collect to contract
        uint256 rToContract = rLP + rTreasury;
        if (rToContract > 0) {
            _rOwned[address(this)] += rToContract;
            emit Transfer(from, address(this), tLP + tTreasury);
        }

        // Reflection: reduce rTotal (standard reflect mechanic)
        if (rReflection > 0) {
            _rTotal -= rReflection;
        }

        // Real burn: reduce both tTotal and rTotal
        if (tBurn > 0) {
            _tTotal -= tBurn;
            _rTotal -= rBurn;
            emit Transfer(from, address(0), tBurn);
        }
    }

    function _approveInternal(address owner_, address spender, uint256 amount) internal {
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    receive() external payable {}
}
```2
