// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply token for Zipvilization (Base). V2 DEX integration via injected router/pair.
 * @dev Implements:
 * - Fixed supply (no mint)
 * - Reflection (r/t dual supply) + real burn
 * - Buy/Sell/Transfer fees (immutable schedule)
 * - Trading gate + anti-whale (maxTx, maxWallet growth)
 * - Treasury timelock (2-step)
 * - SwapBack: converts fee tokens to ETH, funds LP, sends ETH to treasury
 *
 * IMPORTANT:
 * - This is ALPHA core. Audit before deploy.
 * - Pair/router are injected to support Aerodrome V2 (UniswapV2-compatible router style).
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
    /*                         METADATA                           */
    /* ---------------------------------------------------------- */

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    uint256 private constant FEE_DENOM = 1_000_000;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // Base canonical WETH (fallback if _weth == address(0))
    address public constant BASE_WETH = 0x4200000000000000000000000000000000000006;

    /* ---------------------------------------------------------- */
    /*                         SUPPLY                             */
    /* ---------------------------------------------------------- */

    uint256 private constant _tTotal = 100_000_000_000_000 * 10**uint256(decimals); // 100T
    uint256 private constant _maxUint = type(uint256).max;
    uint256 private _rTotal = _maxUint - (_maxUint % _tTotal);

    /* ---------------------------------------------------------- */
    /*                           FEES                             */
    /* ---------------------------------------------------------- */
    // BUY (1% total): 0.5% LP + 0.5% Treasury
    uint256 public constant BUY_LP_FEE = 5_000;
    uint256 public constant BUY_TREASURY_FEE = 5_000;

    // SELL (10% total): 4% burn, 3% reflection, 2% LP, 1% treasury
    uint256 public constant SELL_BURN_FEE = 40_000;
    uint256 public constant SELL_REFLECTION_FEE = 30_000;
    uint256 public constant SELL_LP_FEE = 20_000;
    uint256 public constant SELL_TREASURY_FEE = 10_000;

    // TRANSFER (5% total): 2% burn, 3% reflection
    uint256 public constant TRANSFER_BURN_FEE = 20_000;
    uint256 public constant TRANSFER_REFLECTION_FEE = 30_000;

    /* ---------------------------------------------------------- */
    /*                           LIMITS                           */
    /* ---------------------------------------------------------- */

    // MaxTx: 10B
    uint256 public constant MAX_TX_AMOUNT = 10_000_000_000 * 10**uint256(decimals);

    // Initial max wallet: 30B, grows +10% weekly after 180 days
    uint256 public constant MAX_WALLET_INITIAL = 30_000_000_000 * 10**uint256(decimals);
    uint256 public constant MAX_WALLET_GROWTH_DELAY = 180 days;
    uint256 public constant MAX_WALLET_WEEKLY_GROWTH_BP = 10_000; // 10% in basis points (1e5 denom below)

    uint256 private constant WALLET_GROWTH_DENOM = 100_000; // 1e5 to match prior design language

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

    uint256 public swapThreshold = 200_000_000 * 10**uint256(decimals);       // 200M
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10**uint256(decimals); // 1B
    uint256 public swapBackCooldown = 60; // seconds
    uint256 public lastSwapBackTime;

    bool private _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /* ---------------------------------------------------------- */
    /*                          STATE                             */
    /* ---------------------------------------------------------- */

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isLimitExempt;

    uint256 public immutable deploymentTime;

    /* ---------------------------------------------------------- */
    /*                           EVENTS                           */
    /* ---------------------------------------------------------- */

    event TradingEnabled();
    event SwapBack(uint256 tokensSwapped, uint256 ethToTreasury, uint256 tokensToLP, uint256 ethToLP);
    event TreasuryChangeInitiated(address indexed newTreasury, uint256 executeAfter);
    event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);

    /* ---------------------------------------------------------- */
    /*                        CONSTRUCTOR                         */
    /* ---------------------------------------------------------- */

    constructor(
        address _router,
        address _pair,
        address _weth,
        address _treasury
    ) {
        require(_router != address(0) && _pair != address(0) && _treasury != address(0), "ZERO_ADDR");

        address resolvedWeth = (_weth == address(0)) ? BASE_WETH : _weth;

        router = _router;
        pair = _pair;
        weth = resolvedWeth;

        treasury = _treasury;
        deploymentTime = block.timestamp;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // fee exemptions
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasury] = true;

        // limit exemptions
        isLimitExempt[msg.sender] = true;
        isLimitExempt[address(this)] = true;
        isLimitExempt[treasury] = true;
        isLimitExempt[router] = true;
        isLimitExempt[pair] = true;
        isLimitExempt[DEAD] = true;
    }

    /* ---------------------------------------------------------- */
    /*                      ERC20 STANDARD                        */
    /* ---------------------------------------------------------- */

    function totalSupply() external pure override returns (uint256) {
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
        unchecked { _allowances[from][msg.sender] = currentAllowance - amount; }
        _transfer(from, to, amount);
        return true;
    }

    /* ---------------------------------------------------------- */
    /*                     REFLECTION HELPERS                     */
    /* ---------------------------------------------------------- */

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        uint256 rate = _getRate();
        return rAmount / rate;
    }

    function _getRate() internal view returns (uint256) {
        return _rTotal / _tTotal;
    }

    /* ---------------------------------------------------------- */
    /*                      LIMITS / WALLET                       */
    /* ---------------------------------------------------------- */

    function maxWallet() public view returns (uint256) {
        // Before growth delay: fixed
        if (block.timestamp < deploymentTime + MAX_WALLET_GROWTH_DELAY) {
            return MAX_WALLET_INITIAL;
        }

        // After delay: grows weekly +10%
        uint256 weeksElapsed = (block.timestamp - (deploymentTime + MAX_WALLET_GROWTH_DELAY)) / 1 weeks;

        // growthFactor = (1.10 ^ weeksElapsed) approximated iteratively (weeks are small in early life)
        uint256 m = MAX_WALLET_INITIAL;
        for (uint256 i = 0; i < weeksElapsed; i++) {
            m = (m * (WALLET_GROWTH_DENOM + MAX_WALLET_WEEKLY_GROWTH_BP)) / WALLET_GROWTH_DENOM;
            // hard cap at total supply
            if (m >= _tTotal) return _tTotal;
        }
        return m;
    }

    /* ---------------------------------------------------------- */
    /*                       TRANSFER CORE                        */
    /* ---------------------------------------------------------- */

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "ZERO_AMOUNT");

        // trading gate
        if (!tradingEnabled) {
            require(isFeeExempt[from] || isFeeExempt[to], "TRADING_OFF");
        }

        // limits
        if (!isLimitExempt[from] && !isLimitExempt[to]) {
            require(amount <= MAX_TX_AMOUNT, "MAX_TX");

            // max wallet applies for regular receives (exclude sells to pair)
            if (to != pair) {
                uint256 newBal = balanceOf(to) + amount;
                require(newBal <= maxWallet(), "MAX_WALLET");
            }
        }

        // swapback (only on sells, not during swaps)
        if (
            swapBackEnabled &&
            !_inSwap &&
            tradingEnabled &&
            to == pair &&
            block.timestamp >= lastSwapBackTime + swapBackCooldown
        ) {
            uint256 contractTokenBal = balanceOf(address(this));
            if (contractTokenBal >= swapThreshold) {
                _swapBack(contractTokenBal);
                lastSwapBackTime = block.timestamp;
            }
        }

        bool takeFee = !(isFeeExempt[from] || isFeeExempt[to]);
        uint8 txType = _txType(from, to);

        _tokenTransfer(from, to, amount, takeFee, txType);
    }

    function _txType(address from, address to) internal view returns (uint8) {
        if (from == pair) return 1; // buy
        if (to == pair) return 2;   // sell
        return 3;                   // transfer
    }

    function _tokenTransfer(address from, address to, uint256 tAmount, bool takeFee, uint8 txType) internal {
        uint256 rate = _getRate();
        uint256 rAmount = tAmount * rate;

        // remove full amount from sender
        _rOwned[from] -= rAmount;

        if (!takeFee) {
            _rOwned[to] += rAmount;
            emit Transfer(from, to, tAmount);
            return;
        }

        // fee schedule
        (uint256 burnFee, uint256 reflFee, uint256 lpFee, uint256 treasFee) = _feesFor(txType);

        uint256 tBurn = (tAmount * burnFee) / FEE_DENOM;
        uint256 tRefl = (tAmount * reflFee) / FEE_DENOM;
        uint256 tLP   = (tAmount * lpFee)   / FEE_DENOM;
        uint256 tTres = (tAmount * treasFee)/ FEE_DENOM;

        uint256 tFeeTotal = tBurn + tRefl + tLP + tTres;
        uint256 tTransfer = tAmount - tFeeTotal;

        // recipient gets net
        _rOwned[to] += (tTransfer * rate);
        emit Transfer(from, to, tTransfer);

        // burn (real)
        if (tBurn > 0) {
            _rOwned[DEAD] += (tBurn * rate);
            emit Transfer(from, DEAD, tBurn);
        }

        // LP + treasury fees go to contract for swapback
        uint256 tToContract = tLP + tTres;
        if (tToContract > 0) {
            _rOwned[address(this)] += (tToContract * rate);
            emit Transfer(from, address(this), tToContract);
        }

        // reflection fee reduces _rTotal (standard reflection model)
        if (tRefl > 0) {
            _reflectFee(tRefl, rate);
        }
    }

    function _feesFor(uint8 txType) internal pure returns (uint256 burnFee, uint256 reflFee, uint256 lpFee, uint256 treasFee) {
        if (txType == 1) {
            // buy
            return (0, 0, BUY_LP_FEE, BUY_TREASURY_FEE);
        }
        if (txType == 2) {
            // sell
            return (SELL_BURN_FEE, SELL_REFLECTION_FEE, SELL_LP_FEE, SELL_TREASURY_FEE);
        }
        // transfer
        return (TRANSFER_BURN_FEE, TRANSFER_REFLECTION_FEE, 0, 0);
    }

    function _reflectFee(uint256 tRefl, uint256 rate) internal {
        uint256 rRefl = tRefl * rate;
        _rTotal -= rRefl;
        // no Transfer emitted for reflection redistribution (standard reflection behavior)
    }

    /* ---------------------------------------------------------- */
    /*                         SWAPBACK                           */
    /* ---------------------------------------------------------- */

    function _swapBack(uint256 contractTokenBal) internal lockTheSwap {
        // cap amount swapped to avoid large price impact
        uint256 amountToProcess = contractTokenBal;
        if (amountToProcess > swapBackMaxAmount) amountToProcess = swapBackMaxAmount;

        // Split: LP portion vs Treasury portion based on current SELL LP/TREAS weights
        // We only hold LP+TREAS tokens in contract (not burn/refl).
        uint256 totalSwapFees = SELL_LP_FEE + SELL_TREASURY_FEE;
        if (totalSwapFees == 0) return;

        uint256 tokensForLPHalf = (amountToProcess * SELL_LP_FEE) / totalSwapFees / 2;
        uint256 tokensToSwapForETH = amountToProcess - tokensForLPHalf;

        // swap tokens -> ETH
        _approve(address(this), router, tokensToSwapForETH);

        address;
        path[0] = address(this);
        path[1] = weth;

        uint256 ethBefore = address(this).balance;

        IDexV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwapForETH,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethGained = address(this).balance - ethBefore;
        if (ethGained == 0) return;

        // Determine ETH split: LP gets proportional to tokensForLPHalf, treasury gets the rest
        uint256 ethForLP = (ethGained * tokensForLPHalf) / tokensToSwapForETH;
        uint256 ethForTreasury = ethGained - ethForLP;

        // Add liquidity (token + ETH) -> send LP to owner (or could be DEAD in future, but keep owner for now)
        uint256 tokensToLP = tokensForLPHalf;
        if (tokensToLP > 0 && ethForLP > 0) {
            _approve(address(this), router, tokensToLP);
            IDexV2Router(router).addLiquidityETH{value: ethForLP}(
                address(this),
                tokensToLP,
                0,
                0,
                owner,
                block.timestamp
            );
        }

        // Send ETH to treasury
        if (ethForTreasury > 0) {
            (bool ok,) = payable(treasury).call{value: ethForTreasury}("");
            require(ok, "TREASURY_SEND_FAIL");
        }

        emit SwapBack(tokensToSwapForETH, ethForTreasury, tokensToLP, ethForLP);
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /* ---------------------------------------------------------- */
    /*                          ADMIN                             */
    /* ---------------------------------------------------------- */

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "TRADING_ON");
        tradingEnabled = true;
        emit TradingEnabled();
    }

    function setSwapBackEnabled(bool enabled) external onlyOwner {
        swapBackEnabled = enabled;
    }

    function setSwapParams(uint256 _threshold, uint256 _maxAmount, uint256 _cooldown) external onlyOwner {
        // keep sane minimums
        require(_threshold <= 5_000_000_000 * 10**uint256(decimals), "THRESH_TOO_HIGH");
        require(_maxAmount >= _threshold, "MAX_LT_THRESH");
        require(_cooldown <= 3600, "COOLDOWN_TOO_HIGH");
        swapThreshold = _threshold;
        swapBackMaxAmount = _maxAmount;
        swapBackCooldown = _cooldown;
    }

    // Treasury timelock (2-step)
    function initiateTreasuryChange(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "ZERO_ADDR");
        pendingTreasury = newTreasury;
        treasuryChangeTime = block.timestamp + TREASURY_CHANGE_DELAY;
        emit TreasuryChangeInitiated(newTreasury, treasuryChangeTime);
    }

    function executeTreasuryChange() external onlyOwner {
        require(pendingTreasury != address(0), "NO_PENDING");
        require(block.timestamp >= treasuryChangeTime, "TOO_EARLY");
        address old = treasury;
        treasury = pendingTreasury;
        pendingTreasury = address(0);
        treasuryChangeTime = 0;
        isFeeExempt[treasury] = true;
        isLimitExempt[treasury] = true;
        emit TreasuryChanged(old, treasury);
    }

    function setFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
    }

    function setLimitExempt(address account, bool exempt) external onlyOwner {
        isLimitExempt[account] = exempt;
    }

    /* ---------------------------------------------------------- */
    /*                        RECEIVE ETH                          */
    /* ---------------------------------------------------------- */

    receive() external payable {}
}
