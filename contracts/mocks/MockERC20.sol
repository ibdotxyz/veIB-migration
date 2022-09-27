// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using ERC20
contract MockERC20 is ERC20 {
    constructor() payable ERC20("Test", "TEST") {}

    // AnyswapV6ERC20.mint
    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }
}
