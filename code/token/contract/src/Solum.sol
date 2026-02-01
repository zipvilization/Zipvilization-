// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 * @dev V2-style router (Aerodrome / Uniswap compatible)
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

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNER_ONLY");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}

contract Solum is IERC20, Ownable {

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    uint256 private constant TOTAL_SUPPLY =
        100_000_000_000_000 * 10 ** decimals; // 100T

    uint256 private constant FEE_DENOM = 1_000_000;

    address public immutable router;
    address public immutable pair;
    address public immutable weth;
    address public treasury;

    bool public tradingEnabled;
    bool private inSwap;

    uint256 public swapThreshold = 200_000_000 * 10 ** decimals;
    uint256 public swapBackMaxAmount = 1_000_000_000 * 10 ** decimals;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    modifier lockSwap() {
        inSwap = true;
        _;
        inSwap = false;
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

        balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    /* ---------------- ERC20 ---------------- */

    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
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
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amount, "ALLOWANCE");
        allowances[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    /* ---------------- INTERNAL ---------------- */

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "ZERO_AMOUNT");

        if (!tradingEnabled) {
            require(from == owner || to == owner, "TRADING_DISABLED");
        }

        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);

        if (
            !inSwap &&
            from != pair &&
            balances[address(this)] >= swapThreshold
        ) {
            _swapBack();
        }
    }

    function _swapBack() internal lockSwap {
        uint256 amountToSwap = balances[address(this)];
        if (amountToSwap > swapBackMaxAmount) {
            amountToSwap = swapBackMaxAmount;
        }

        allowances[address(this)][router] = amountToSwap;

        address;
        path[0] = address(this);
        path[1] = weth;

        IDexV2Router(router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                treasury,
                block.timestamp
            );

        balances[address(this)] -= amountToSwap;
    }

    /* ---------------- ADMIN ---------------- */

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    receive() external payable {}
}
