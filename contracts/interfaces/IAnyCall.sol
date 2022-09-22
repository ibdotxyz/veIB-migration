// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAnyCall {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;

    function executor() external view returns (address executor);
}
