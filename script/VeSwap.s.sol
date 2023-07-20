// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "src/VeSwapV2Pair.sol";
import "src/VeSwapV2Factory.sol";

import "forge-std/Script.sol";

contract Monate is Script {
    VeSwapV2Pair public veswap;
    VeSwapV2Factory factory;

    ERC20 token0;
    ERC20 token1;
    address user = address(7);

    function setUp() public {
        vm.startPrank(user);
        token0 = new ERC20("Monate", "TST");
        token1 = new ERC20("Monate", "TST");
        factory = new VeSwapV2Factory();
        veswap = VeSwapV2Pair(factory.createPair(address(token0), address(token1)));
        //vm.stopPrank();
    }

    function run() public {
        //vm.startPrank(user);

        uint amount0 = 1 ether;
        uint amount1 = 1 ether;
        token0.approve(address(veswap), amount0);
        token1.approve(address(veswap), amount1);

        
    }
}
