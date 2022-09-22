// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {
    function claim_many(uint256[] memory _tokenIds) external returns (bool);
}
