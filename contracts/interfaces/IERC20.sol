// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address to, uint256 amount) external;

    function approve(address spender, uint256 value) external returns (bool);
}
