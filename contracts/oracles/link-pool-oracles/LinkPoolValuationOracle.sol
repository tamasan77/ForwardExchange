// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./LinkPoolUintOracle.sol";

/// @title LinkPool oracle for getting the price of a forward contract.
/// @author Tamas An
/// @notice Use this oracle for GET requests to API that calculates value of forward contract
/// @dev Before using oracle. Test if LinkPool uint job and valuation api are up and running
contract LinkPoolValuationOracle is LinkPoolUintOracle {
    int public _decimals_ = 10 ** 2;
    string private constant _apiBaseURL_ = "http://valuation-api.herokuapp.com/price/";
    string public constant _apiPath_ = "price";

    constructor() 
        LinkPoolUintOracle (
            _decimals_,
            _apiBaseURL_,
            _apiPath_
        ) {
    }
}