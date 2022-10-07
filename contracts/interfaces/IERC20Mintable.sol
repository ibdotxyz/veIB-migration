// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}
