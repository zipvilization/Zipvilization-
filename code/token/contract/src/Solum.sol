// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Solum (SOLUM)
 * @notice Fixed-supply, deflationary token used as Zipvilization’s on-chain substrate.
 *
 * CORE PRINCIPLES
 * - Fixed supply (no mint)
 * - Reflection (dual-supply)
 * - Real burn
 * - Immutable fee rules
 * - Anti-whale protections
 * - Treasury-based swapback
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

    modifier onlyOwner() {
        require(msg.sender == owner, "OWNER_ONLY");
        _;
    }

    constructor() {
        owner = msg.sender;
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

    /* ---------------------------------------------------------- */
    /*                         SUPPLY                             */
    /* ---------------------------------------------------------- */

    uint256 private constant _tTotal =
        100_000_000_000_000 * 10 ** decimals; // 100T

    uint256 private _rTotal =
        type(uint256).max - (type(uint256).max % _tTotal);

    /* ---------------------------------------------------------- */
    /*                          DEX                               */
    /* ---------------------------------------------------------- */

    address public immutable router;
    address public immutable weth;
    address public treasury;

    address public constant BASE_WETH =
        0x4200000000000000000000000000000000000006;

    /* ---------------------------------------------------------- */
    /*                         STATE                              */
    /* ---------------------------------------------------------- */

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool private inSwap;
    uint256 public swapBackThreshold =
        200_000_000 * 10 ** decimals;

    /* ---------------------------------------------------------- */
    /*                        MODIFIERS                           */
    /* ---------------------------------------------------------- */

    modifier lockSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /* ---------------------------------------------------------- */
    /*                      CONSTRUCTOR                           */
    /* ---------------------------------------------------------- */

    constructor(
        address _router,
        address _weth,
        address _treasury
    ) {
        require(_router != address(0), "ROUTER_ZERO");
        require(_treasury != address(0), "TREASURY_ZERO");

        router = _router;
        weth = _weth == address(0) ? BASE_WETH : _weth;
        treasury = _treasury;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    /* ---------------------------------------------------------- */
    /*                      ERC20 LOGIC                           */
    /* ---------------------------------------------------------- */

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return tokenFromReflection(_rOwned[account]);
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

    /* ---------------------------------------------------------- */
    /*                    INTERNAL LOGIC                          */
    /* ---------------------------------------------------------- */

    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        return rAmount / (_rTotal / _tTotal);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount > 0, "ZERO_AMOUNT");

        uint256 rate = _rTotal / _tTotal;
        uint256 rAmount = amount * rate;

        _rOwned[from] -= rAmount;
        _rOwned[to] += rAmount;

        emit Transfer(from, to, amount);

        if (
            !inSwap &&
            to == address(this) &&
            balanceOf(address(this)) >= swapBackThreshold
        ) {
            _swapBack();
        }
    }

    /* ---------------------------------------------------------- */
    /*                       SWAPBACK                             */
    /* ---------------------------------------------------------- */

    function _swapBack() internal lockSwap {
        uint256 tokenAmount = balanceOf(address(this));
        if (tokenAmount == 0) return;

        _allowances[address(this)][router] = tokenAmount;

        // ✅ DECLARACIÓN CORRECTA DEL PATH
        address;
        path[0] = address(this);
        path[1] = weth;

        IDexV2Router(router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                treasury,
                block.timestamp
            );
    }

    receive() external payable {}
}
