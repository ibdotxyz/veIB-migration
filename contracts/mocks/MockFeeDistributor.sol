// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/*

@title Curve Fee Distribution modified for ve(3,3) emissions
@author Curve Finance, andrecronje
@license MIT

*/

contract MockFeeDistributor {
    function claim_many(uint256[] memory _tokenIds) external returns (bool) {
        return true;
    }
}
