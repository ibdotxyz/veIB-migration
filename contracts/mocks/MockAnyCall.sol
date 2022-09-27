// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract MockAnyCall {
    address public immutable executor;

    constructor(address _executor) {
        executor = _executor;
    }
}
