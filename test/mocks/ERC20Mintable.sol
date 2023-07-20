// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mintable is ERC20 {
    constructor(string memory,string memory) ERC20("Monate", "MNT") {}

    function mint(address to,uint amount) public {
        _mint(to,amount);
    }
}
