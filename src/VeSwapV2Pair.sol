// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./interfaces/VeSwapV2Callee.sol";

contract VeSwapV2Pair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UQ112x112 for uint224;

    IERC20 public token0;
    IERC20 public token1;

    uint256 constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint112 private _reserve0;
    uint112 private _reserve1;

    uint256 price0CumulativeLast;
    uint256 price1CumulativeLast;
    uint32 blockTimestampLast;

    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error InsufficientLiquidity();
    error AlreadyInitialized();
    error BalanceOverflow();
    error InvalidK();

    event Burn(address indexed from, address to, uint256 liquidity, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, address to, uint256 amount0Out, uint256 amount1Out);
    event Mint(address indexed to, uint256 liquidity, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor() ERC20("Monate", "MNT") {}

    function initialize(address _token0, address _token1) external {
        if (address(token0) != address(0) || address(token1) != address(0)) {
            revert AlreadyInitialized();
        }

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        (uint112 reserve0, uint112 reserve1) = getReserves();

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;
        // save sloads
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / reserve0, (amount1 * _totalSupply) / reserve1);
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);
        _update(balance0, balance1, reserve0, reserve1);
        emit Mint(to, liquidity, amount0, amount1);
    }

    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        amount0 = (liquidity * balance0) / totalSupply();
        amount1 = (liquidity * balance1) / totalSupply();

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);
        token0.safeTransfer(to, amount0);
        token1.safeTransfer(to, amount1);
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
        (uint112 reserve0, uint112 reserve1) = getReserves();
        _update(balance0, balance1, reserve0, reserve1);
        emit Burn(msg.sender, to, liquidity, amount0, amount1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) public nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 reserve0, uint112 reserve1) = getReserves();
        if (amount0Out > reserve0 || amount1Out > reserve1) {
            revert InsufficientLiquidity();
        }
        if (amount0Out > 0) token0.safeTransfer(to, amount0Out);
        if (amount1Out > 0) token1.safeTransfer(to, amount1Out);
        if (data.length != 0) {
            VeSwapV2Callee(to).veswapV2Callee(msg.sender, amount0Out, amount1Out, data);
        }

        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;

        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        // checks sent tokens are correct including fees && slippage
        if (balance0Adjusted * balance1Adjusted < uint256(reserve0) * uint256(reserve1) * (1000_000)) {
            revert InvalidK();
        }
        _update(balance0, balance1, reserve0, reserve1);
        emit Swap(msg.sender, to, amount0Out, amount1Out);
    }

    function getReserves() public view returns (uint112, uint112) {
        return (_reserve0, _reserve1);
    }

    function sync() public {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)), reserve0, reserve1);
    }

    function _update(uint256 balance0, uint256 balance1, uint112 reserve0, uint112 reserve1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert BalanceOverflow();
        }
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;
            if (timeElapsed > 0 && reserve0 > 0 && reserve1 > 0) {
                price0CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) * timeElapsed;
            }
        }
        _reserve0 = uint112(balance0);
        _reserve1 = uint112(balance1);
    }
}
