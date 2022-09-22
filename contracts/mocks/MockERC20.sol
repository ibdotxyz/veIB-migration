// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using ERC20
contract ERC20Mock is ERC20 {
    constructor() payable ERC20("Test", "TEST") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
