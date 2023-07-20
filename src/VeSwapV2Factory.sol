// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VeSwapV2Pair.sol";
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    // function feeTo() external view returns (address);

    // function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/// @title Uniswap Clone for education
/// @author 0xOZ
/// @notice clone made for educational purposes
/// @dev fees are not implemented.
contract VeSwapV2Factory is IUniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    error ZeroAddress();
    error PairExists();
    error IdenticalAddresses();

    // event PairCreated(
    //     address indexed token0,
    //     address indexed token1,
    //     address pair,
    //     uint
    // );

    function allPairsLength() external view returns (uint256 length) {
        length = allPairs.length;
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        pair = pairs[tokenA][tokenB];
    }

    function createPair(address tokenA, address tokenB) public returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();
        if (pairs[token0][token1] != address(0)) revert PairExists();

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new VeSwapV2Pair{salt: salt}());

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);
        VeSwapV2Pair(pair).initialize(token0, token1);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
