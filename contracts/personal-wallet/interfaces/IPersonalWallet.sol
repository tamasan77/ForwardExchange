// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IPersonalWallet interface
interface IPersonalWallet {
    /// @notice Adds new token ot the tokens array if it is not part of the array yet.
    /// @dev Use containsToken mapping to check if array already contains element or not.
    /// @param newToken Address of the new token to be added
    function addNewToken(address newToken) external;

    /// @notice Approves collateral wallet to transfer given amount of collateral.
    /// @param collateralWallet Address of the collateral wallet that needs approval.
    /// @param collateralToken Address of the token to be approved.
    /// @param amount Amount of tokens to be approved.
    function approveCollateral(address collateralWallet, address collateralToken, uint256 amount) 
        external;
}