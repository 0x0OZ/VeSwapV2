// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "src/VeSwapV2Pair.sol";
import "lib/forge-std/src/Test.sol";
import "./mocks/ERC20Mintable.sol";

contract Monate is Test {
    VeSwapV2Pair public veswap;
    ERC20Mintable token0;
    ERC20Mintable token1;
    address deployer = address(7);
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    function setUp() public {
        vm.startPrank(deployer);
        token0 = new ERC20Mintable("Monate", "TST");
        token1 = new ERC20Mintable("Monate", "TST");
        veswap = VeSwapV2Pair(createPair(address(token0), address(token1)));
        tokensMint(address(this), 100 ether);
        vm.stopPrank();
    }

    // function testCreatePair() external {
    //     address tokenA = address(new ERC20Mintable("Monate1", "TST"));
    //     address tokenB = address(new ERC20Mintable("Monate2", "TST"));
    //     address pair = factory.createPair(tokenA, tokenB);
    //     assertNotEq(pair, address(0));
    //     assertEq(factory.getPair(tokenA, tokenB), pair);
    //     vm.expectRevert(VeSwapV2Factory.PairExists.selector);
    //     factory.createPair(tokenA, tokenB);
    // }
    function createPair(address tokenA, address tokenB) public returns (address pair) {
        if (tokenA == tokenB) revert("IdenticalAddresses");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) revert("ZeroAddress");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new VeSwapV2Pair{salt: salt}());
        VeSwapV2Pair(pair).initialize(token0, token1);
    }

   

    function testAddLiquidity() public {
        uint256 amount0 = 10 ether;
        uint256 amount1 = 10 ether;
        address to = address(this);
        addLiquidity(to, to, amount0, amount1);
        uint256 amount = amount0 < amount1 ? amount0 : amount1;
        assertEq(veswap.balanceOf(address(this)), amount - MINIMUM_LIQUIDITY);
    }

    function testAddLiquidityWhenThereLiquidity() public {
        address user = address(this);
        addLiquidity(user, user, 5 ether, 5 ether);
        assertEq(veswap.balanceOf(address(this)), 5 ether - MINIMUM_LIQUIDITY);
        user = address(7);
        addLiquidity(user, user, 5 ether, 2 ether);
        assertEq(veswap.balanceOf(user), 2 ether);
    }

 function addLiquidity(address from, address to, uint256 amount0, uint256 amount1) private {
        vm.startPrank(from);
        uint256 amount = amount0 > amount1 ? amount0 : amount1;
        tokensMint(to, amount);
        token0.transfer(address(veswap), amount0);
        token1.transfer(address(veswap), amount1);
        veswap.mint(to);
        vm.stopPrank();
    }
    function tokensMint(address to, uint256 amount) private {
        token0.mint(to, amount);
        token1.mint(to, amount);
    }
}
