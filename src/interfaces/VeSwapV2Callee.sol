// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.16;

interface VeSwapV2Callee {
    function veswapV2Callee(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external;
}