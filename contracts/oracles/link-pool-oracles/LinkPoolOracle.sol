// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../ChainlinkOracle.sol";

/// @title LinkPool oracle skeleton.
/// @author Tamas An
/// @notice Use this oracle for jobs offered by LinkPool on Kovan
/// @dev Before using oracle. Test if LinkPool is up and running.
contract LinkPoolOracle is ChainlinkOracle {
    address public _oracleAddress = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
    address public _linkAddress = 0xa36085F69e2889c224210F603D836748e7dC0088;
    uint256 public _fee = 0.1 * 10 ** 18; //0.1 LINK

    constructor (
        bytes32 _jobId,
        int _decimals, 
        string memory _apiBaseURL, 
        string memory _apiPath, 
        bool _isSignedResult)
        ChainlinkOracle (
            _oracleAddress, 
            _jobId,
            _linkAddress,
            _fee,
            _decimals,
            _apiBaseURL,
            _apiPath,
            _isSignedResult
        ) {
    }
}