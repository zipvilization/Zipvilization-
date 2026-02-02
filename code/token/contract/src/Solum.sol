// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev Base network. Deploy using a V2-style router compatible with:
 *      - swapExactTokensForETHSupportingFeeOnTransferTokens
 *      - addLiquidityETH
 *      - getAmountsOut (optional; used for best-effort minOut)
 *
 * CORE PRINCIPLES:
 * - Fixed supply (no mint, no inflation)
 * - Reflection (dual-supply) + real burn (supply decreases)
 * - Anti-whale protections (maxTx + dynamic maxWallet)
 * - Treasury timelock (propose/confirm)
 * - SwapBack controls (pause + cooldown + cap + best-effort slippage guard)
 * - Fee policy: ONLY-DECREASING, timelocked, max 5 changes per tx-type
 *
 * FEES (TOTAL-ONLY, INDEPENDENT):
 * - BUY fee total  (split fixed 50% LP / 50% Treasury)
 * - SELL fee total (split fixed 4/3/2/1 Burn/Reflection/LP/Treasury)
 * - TRANSFER fee total (split fixed 2/3 Burn/Reflection)
 *
 * IMPORTANT:
 * - Pair address MUST be injected correctly at deployment.
 * - This contract is self-contained (no external deps).
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
 * @dev Minimal V2-style router interface.
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

contract SolumToken is IERC20, Ownable {
    /* ---------- METADATA ---------- */
    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8  public constant decimals = 18;

    /* ---------- SUPPLY (DUAL) ---------- */
    uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    /* ---------- DENOMS ---------- */
    uint256 private constant FEE_DENOM = 1_000_000;  // ppm
    uint256 private constant BPS_DENOM = 10_000;     // basis points

    /* ---------- INITIAL FEE TOTALS (ppm) ---------- */
    // BUY: 1% total
    uint256 public constant BUY_FEE_INITIAL = 10_000;
    // SELL: 10% total
    uint256 public constant SELL_FEE_INITIAL = 100_000;
    // TRANSFER: 5% total
    uint256 public constant TRANSFER_FEE_INITIAL = 50_000;

    /* ---------- FEE TOTALS (MUTABLE, ONLY-DECREASING) ---------- */
    uint256 public buyFeeTotal;       // ppm
    uint256 public sellFeeTotal;      // ppm
    uint256 public transferFeeTotal;  // ppm

    /* ---------- FEE CHANGE POLICY ---------- */
    uint8 public constant FEE_MAX_CHANGES = 5;
    uint256 public constant FEE_TIMELOCK = 24 hours;

    // BUY fee change state
    uint256 public pendingBuyFeeTotal;
    uint256 public buyFeeChangeTime;
    uint8   public buyFeeChangesUsed;
    bool    public buyFeeFrozen;

    // SELL fee change state
    uint256 public pendingSellFeeTotal;
    uint256 public sellFeeChangeTime;
    uint8   public sellFeeChangesUsed;
    bool    public sellFeeFrozen;

    // TRANSFER fee change state
    uint256 public pendingTransferFeeTotal;
    uint256 public transferFeeChangeTime;
    uint8   public transferFeeChangesUsed;
    bool    public transferFeeFrozen;

    /* ---------- LIMITS ---------- */
    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**decimals; // 10B fixed
    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**decimals; // 30B
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;

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
    bool public swapBackEnabled = true;
    bool public tradingEnabled = false;

    uint256 public swapThreshold = 200_000_000 * 10**decimals;      // 200M tokens (tune)
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**decimals; // 1B tokens max per swap (tune)
    uint256 public swapBackCooldown = 60;                           // seconds (tune)
    uint256 public slippageBps = 300;                               // 3% in bps (tune 50..800 typical)

    uint256 public lastSwapBackTime;
    bool private _inSwapBack;

    /* ---------- STATE ---------- */
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExempt;

    uint256 public immutable deploymentTime;

    // accounting for swapBack buckets (accurate)
    uint256 private _tokensForLiquidity; // token units (tAmount)
    uint256 private _tokensForTreasury;  // token units (tAmount)

    /* ---------- EVENTS ---------- */
    event TradingEnabled();
    event SwapBackPaused(bool paused);
    event TreasuryProposed(address indexed newTreasury, uint256 availableAt);
    event TreasuryConfirmed(address indexed newTreasury);
    event SwapBackConfigUpdated(uint256 threshold, uint256 maxAmount, uint256 cooldown, uint256 slippageBps);

    event BuyFeeProposed(uint256 newTotalFee, uint256 availableAt);
    event BuyFeeApplied(uint256 newTotalFee, uint8 changesUsed);
    event BuyFeeFrozen(uint8 changesUsed);

    event SellFeeProposed(uint256 newTotalFee, uint256 availableAt);
    event SellFeeApplied(uint256 newTotalFee, uint8 changesUsed);
    event SellFeeFrozen(uint8 changesUsed);

    event TransferFeeProposed(uint256 newTotalFee, uint256 availableAt);
    event TransferFeeApplied(uint256 newTotalFee, uint8 changesUsed);
    event TransferFeeFrozen(uint8 changesUsed);

    modifier lockTheSwap() {
        _inSwapBack = true;
        _;
        _inSwapBack = false;
    }

    constructor(
        address _router,
        address _pair,
        address _treasury
    ) {
        require(_router != address(0) && _pair != address(0) && _treasury != address(0), "ZERO_ADDR");

        router = _router;
        pair = _pair;

        weth = IDexV2Router(_router).WETH();
        require(weth != address(0), "WETH_ZERO");

        treasury = _treasury;
        deploymentTime = block.timestamp;

        // init fees
        buyFeeTotal = BUY_FEE_INITIAL;
        sellFeeTotal = SELL_FEE_INITIAL;
        transferFeeTotal = TRANSFER_FEE_INITIAL;

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

    receive() external payable {}

    /* ============================== */
    /* ======= ERC20 LOGIC ========== */
    /* ============================== */

    function totalSupply() external view override returns (uint256) { return _tTotal; }

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
        swapBackEnabled = !paused;
        emit SwapBackPaused(paused);
    }

    function setSwapBackConfig(
        uint256 threshold,
        uint256 maxAmount,
        uint256 cooldownSeconds,
        uint256 newSlippageBps
    ) external onlyOwner {
        require(newSlippageBps >= 50 && newSlippageBps <= 800, "SLIPPAGE_RANGE");
        require(maxAmount >= threshold, "MAX_LT_THRESHOLD");
        require(cooldownSeconds <= 15 minutes, "COOLDOWN_TOO_HIGH");

        swapThreshold = threshold;
        swapBackMaxAmount = maxAmount;
        swapBackCooldown = cooldownSeconds;
        slippageBps = newSlippageBps;

        emit SwapBackConfigUpdated(threshold, maxAmount, cooldownSeconds, newSlippageBps);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner { isFeeExempt[account] = exempt; }
    function setLimitExempt(address account, bool exempt) external onlyOwner { isLimitExempt[account] = exempt; }

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

        isFeeExempt[treasury] = true;
        isLimitExempt[treasury] = true;

        emit TreasuryConfirmed(treasury);
    }

    /* ============================== */
    /* ====== FEE REDUCTIONS ======== */
    /* ============================== */

    // ---- BUY ----
    function proposeBuyFeeReduction(uint256 newTotalFee) external onlyOwner {
        require(!buyFeeFrozen, "BUY_FEE_FROZEN");
        require(buyFeeChangesUsed < FEE_MAX_CHANGES, "BUY_FEE_MAX_CHANGES");
        require(newTotalFee <= buyFeeTotal, "ONLY_DECREASING");
        require(newTotalFee <= BUY_FEE_INITIAL, "ABOVE_INITIAL");
        pendingBuyFeeTotal = newTotalFee;
        buyFeeChangeTime = block.timestamp + FEE_TIMELOCK;
        emit BuyFeeProposed(newTotalFee, buyFeeChangeTime);
    }

    function confirmBuyFeeReduction() external onlyOwner {
        require(buyFeeChangeTime != 0, "NO_PENDING");
        require(block.timestamp >= buyFeeChangeTime, "TIMELOCK");
        buyFeeTotal = pendingBuyFeeTotal;
        pendingBuyFeeTotal = 0;
        buyFeeChangeTime = 0;
        buyFeeChangesUsed++;

        emit BuyFeeApplied(buyFeeTotal, buyFeeChangesUsed);

        if (buyFeeTotal == 0 || buyFeeChangesUsed >= FEE_MAX_CHANGES) {
            buyFeeFrozen = true;
            emit BuyFeeFrozen(buyFeeChangesUsed);
        }
    }

    // ---- SELL ----
    function proposeSellFeeReduction(uint256 newTotalFee) external onlyOwner {
        require(!sellFeeFrozen, "SELL_FEE_FROZEN");
        require(sellFeeChangesUsed < FEE_MAX_CHANGES, "SELL_FEE_MAX_CHANGES");
        require(newTotalFee <= sellFeeTotal, "ONLY_DECREASING");
        require(newTotalFee <= SELL_FEE_INITIAL, "ABOVE_INITIAL");
        pendingSellFeeTotal = newTotalFee;
        sellFeeChangeTime = block.timestamp + FEE_TIMELOCK;
        emit SellFeeProposed(newTotalFee, sellFeeChangeTime);
    }

    function confirmSellFeeReduction() external onlyOwner {
        require(sellFeeChangeTime != 0, "NO_PENDING");
        require(block.timestamp >= sellFeeChangeTime, "TIMELOCK");
        sellFeeTotal = pendingSellFeeTotal;
        pendingSellFeeTotal = 0;
        sellFeeChangeTime = 0;
        sellFeeChangesUsed++;

        emit SellFeeApplied(sellFeeTotal, sellFeeChangesUsed);

        if (sellFeeTotal == 0 || sellFeeChangesUsed >= FEE_MAX_CHANGES) {
            sellFeeFrozen = true;
            emit SellFeeFrozen(sellFeeChangesUsed);
        }
    }

    // ---- TRANSFER ----
    function proposeTransferFeeReduction(uint256 newTotalFee) external onlyOwner {
        require(!transferFeeFrozen, "TRANSFER_FEE_FROZEN");
        require(transferFeeChangesUsed < FEE_MAX_CHANGES, "TRANSFER_FEE_MAX_CHANGES");
        require(newTotalFee <= transferFeeTotal, "ONLY_DECREASING");
        require(newTotalFee <= TRANSFER_FEE_INITIAL, "ABOVE_INITIAL");
        pendingTransferFeeTotal = newTotalFee;
        transferFeeChangeTime = block.timestamp + FEE_TIMELOCK;
        emit TransferFeeProposed(newTotalFee, transferFeeChangeTime);
    }

    function confirmTransferFeeReduction() external onlyOwner {
        require(transferFeeChangeTime != 0, "NO_PENDING");
        require(block.timestamp >= transferFeeChangeTime, "TIMELOCK");
        transferFeeTotal = pendingTransferFeeTotal;
        pendingTransferFeeTotal = 0;
        transferFeeChangeTime = 0;
        transferFeeChangesUsed++;

        emit TransferFeeApplied(transferFeeTotal, transferFeeChangesUsed);

        if (transferFeeTotal == 0 || transferFeeChangesUsed >= FEE_MAX_CHANGES) {
            transferFeeFrozen = true;
            emit TransferFeeFrozen(transferFeeChangesUsed);
        }
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
        // rTotal and tTotal always decrease together for real burn
        return _rTotal / _tTotal;
    }

    function _maxWalletNow() internal view returns (uint256) {
        if (block.timestamp < deploymentTime + MAX_WALLET_GROWTH_DELAY) {
            return MAX_WALLET_INITIAL;
        }

        uint256 weeksElapsed = (block.timestamp - (deploymentTime + MAX_WALLET_GROWTH_DELAY)) / 1 weeks;

        // Avoid pathological gas far in the future
        if (weeksElapsed > 520) return type(uint256).max;

        uint256 limit = MAX_WALLET_INITIAL;
        // +10% weekly compounding
        for (uint256 i = 0; i < weeksElapsed; i++) {
            limit = (limit * 110) / 100;
        }
        return limit;
    }

    function _shouldSwapBack(address from, address to) internal view returns (bool) {
        if (!swapBackEnabled) return false;
        if (_inSwapBack) return false;
        if (!tradingEnabled) return false;

        // Trigger primarily on sells
        if (to != pair) return false;

        if (block.timestamp < lastSwapBackTime + swapBackCooldown) return false;

        uint256 contractTokenBalance = tokenFromReflection(_rOwned[address(this)]);
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

        // SwapBack (best-effort, prior to applying this sell)
        if (_shouldSwapBack(from, to)) {
            _swapBack();
        }

        bool isBuy = (from == pair);
        bool isSell = (to == pair);

        bool takeFee = !_inSwapBack && !(isFeeExempt[from] || isFeeExempt[to]);

        // Wallet limit (only on receive; ignore pair/router)
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
                uint256 tBuyFee = (tAmount * buyFeeTotal) / FEE_DENOM;
                // 50/50 LP/Treasury
                tLP = tBuyFee / 2;
                tTreasury = tBuyFee - tLP;
            } else if (isSell) {
                uint256 tSellFee = (tAmount * sellFeeTotal) / FEE_DENOM;
                // 4/3/2/1 over 10
                tBurn = (tSellFee * 4) / 10;
                tReflection = (tSellFee * 3) / 10;
                tLP = (tSellFee * 2) / 10;
                tTreasury = tSellFee - tBurn - tReflection - tLP;
            } else {
                uint256 tTransferFee = (tAmount * transferFeeTotal) / FEE_DENOM;
                // 2/3 over 5
                tBurn = (tTransferFee * 2) / 5;
                tReflection = tTransferFee - tBurn;
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

        // Handle LP + Treasury fee: collected to contract (later swapBack)
        uint256 tToContract = tLP + tTreasury;
        uint256 rToContract = rLP + rTreasury;
        if (rToContract > 0) {
            _rOwned[address(this)] += rToContract;
            emit Transfer(from, address(this), tToContract);

            // accurate bucket accounting
            _tokensForLiquidity += tLP;
            _tokensForTreasury += tTreasury;
        }

        // Handle reflection: reduce rTotal (standard reflect mechanic)
        if (rReflection > 0) {
            _rTotal -= rReflection;
        }

        // Handle real burn: reduce both tTotal and rTotal to keep rate consistent
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

        uint256 contractTokenBalance = tokenFromReflection(_rOwned[address(this)]);
        if (contractTokenBalance < swapThreshold) return;

        uint256 amountToProcess = contractTokenBalance;
        if (amountToProcess > swapBackMaxAmount) amountToProcess = swapBackMaxAmount;

        // total buckets tracked
        uint256 totalBucket = _tokensForLiquidity + _tokensForTreasury;
        if (totalBucket == 0) return;

        // scale buckets if processing less than totalBucket
        uint256 liqTokens = _tokensForLiquidity;
        uint256 treTokens = _tokensForTreasury;

        if (amountToProcess < totalBucket) {
            liqTokens = (liqTokens * amountToProcess) / totalBucket;
            treTokens = amountToProcess - liqTokens; // remainder
        } else {
            // process entire buckets
            amountToProcess = totalBucket;
        }

        // reduce stored buckets
        if (liqTokens > _tokensForLiquidity) liqTokens = _tokensForLiquidity;
        _tokensForLiquidity -= liqTokens;

        if (treTokens > _tokensForTreasury) treTokens = _tokensForTreasury;
        _tokensForTreasury -= treTokens;

        // Liquidity: split token side half/half
        uint256 tokensForLiquidityHalf = liqTokens / 2;
        uint256 tokensToSwapForETH = (liqTokens - tokensForLiquidityHalf) + treTokens;

        // Approve router
        _approveInternal(address(this), router, tokensForLiquidityHalf + tokensToSwapForETH);

        uint256 ethBefore = address(this).balance;

        // Swap tokensToSwapForETH for ETH, best-effort minOut
        uint256 minOut = _computeMinOut(tokensToSwapForETH);
        _swapTokensForETH(tokensToSwapForETH, minOut);

        uint256 ethGained = address(this).balance - ethBefore;
        if (ethGained == 0) return;

        // split ETH: portion for treasury vs liquidity based on token swap origin
        // token swap is (liqHalfSwap + treasuryTokens)
        uint256 liqSwapPart = (liqTokens - tokensForLiquidityHalf);
        uint256 denom = liqSwapPart + treTokens;
        if (denom == 0) return;

        uint256 ethForTreasury = (ethGained * treTokens) / denom;
        uint256 ethForLiquidity = ethGained - ethForTreasury;

        // Add liquidity (mins set to 0 to avoid DoS; price impact already controlled by caps)
        if (tokensForLiquidityHalf > 0 && ethForLiquidity > 0) {
            _addLiquidity(tokensForLiquidityHalf, ethForLiquidity);
        }

        // Treasury payout
        if (ethForTreasury > 0) {
            (bool ok, ) = treasury.call{value: ethForTreasury}("");
            require(ok, "TREASURY_SEND_FAIL");
        }
    }

    function _computeMinOut(uint256 amountIn) internal view returns (uint256) {
        // Best-effort: if router.getAmountsOut is available, apply slippage bps
        address;
        path[0] = address(this);
        path[1] = weth;

        try IDexV2Router(router).getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            if (amounts.length >= 2 && amounts[1] > 0) {
                uint256 quoted = amounts[1];
                uint256 minOut = (quoted * (BPS_DENOM - slippageBps)) / BPS_DENOM;
                return minOut;
            }
        } catch {
            // fallback
        }
        return 0;
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
}
