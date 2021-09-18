// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./LinkPoolOracle.sol";

/// @title LinkPool int oracle skeleton.
/// @author Tamas An
/// @notice Use this oracle for making GET int256 jobs on LinkPool.
/// @dev Before using oracle. Test if LinkPool int job is up and running.
contract LinkPoolIntOracle is LinkPoolOracle {
    bytes32 public __jobId = "2649fc4ca83c4016bfd2d15765592bee";

    constructor (
        int __decimals, 
        string memory __apiBaseURL, 
        string memory __apiPath
    ) LinkPoolOracle(
        __jobId,
        __decimals,
        __apiBaseURL,
        __apiPath, 
        true
    ) {
    }
}