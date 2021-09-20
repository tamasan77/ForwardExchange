// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface IForwardContract {
    function initiateForward(
        address _long, 
        address _short,
        uint256 _expirationDate,
        address _longWallet, 
        address _shortWallet, 
        uint _exposureMarginRate,
        uint _maintenanceMarginRate, 
        address _collateralTokenAddress) 
        external 
        returns (bool initiated_);
}