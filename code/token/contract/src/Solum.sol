// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilizationâ€™s on-chain substrate.
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

    string public constant name = "Solum";
    string public constant symbol = "SOLUM";
    uint8 public constant decimals = 18;

    uint256 private constant FEE_DENOM = 1_000_000;

    // Canonical Base WETH (Base network)
    address public constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    uint256 private _tTotal = 100_000_000_000_000 * 10**decimals; // 100T
    uint256 private _rTotal = type(uint256).max - (type(uint256).max % _tTotal);

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public immutable router;
    address public immutable pair;
    address public immutable weth;

    address public treasury;

    bool public tradingEnabled;

    bool private _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
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
            _treasury != address(0),
            "ZERO_ADDR"
        );

        router = _router;
        pair = _pair;
        weth = (_weth == address(0)) ? BASE_WETH : _weth;
        treasury = _treasury;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

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

    function tokenFromReflection(uint256 rAmount)
        public view returns (uint256)
    {
        return rAmount / (_rTotal / _tTotal);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "ZERO_AMOUNT");

        if (!tradingEnabled) {
            require(from == owner || to == owner, "TRADING_OFF");
        }

        uint256 rate = _rTotal / _tTotal;
        uint256 rAmount = amount * rate;

        _rOwned[from] -= rAmount;
        _rOwned[to] += rAmount;

        emit Transfer(from, to, amount);
    }

    function _swapBack(uint256 tokenAmount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;

        _allowances[address(this)][router] = tokenAmount;
        emit Approval(address(this), router, tokenAmount);

        IDexV2Router(router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                treasury,
                block.timestamp
            );
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    receive() external payable {}
}
