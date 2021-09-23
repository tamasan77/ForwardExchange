// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title ICollateralWallet interface
interface ICollateralWallet {
    event CollateralReturned(address collateralOwner, uint256 remainingBalance);

    /// @notice Transfers initial collateral requirements from personal wallets to this wallet.
    /// @param forwardContract Address of forward contract
    /// @param shortPersonalWallet Personal wallet of short party
    /// @param longPersonalWallet Personal wallet of long party
    /// @param collateralToken Address of collateral token.
    /// @param collateralAmount Amount of collateral to be transfered
    function setupInitialCollateral (
        address forwardContract,
        address shortPersonalWallet,
        address longPersonalWallet,
        address collateralToken,
        uint256 collateralAmount
    ) external;

    // Personal wallet should have approved collateral before calling add collateral
    /// @notice Transfers collateral from personal wallet to collateral wallet.
    /// @param forwardContract Address of the forward contract.
    /// @param fromShort Bool whether collateral is from short or long party of forward contract.
    /// @param amount Amount of collateral to be transfered from personal wallet.
    function addCollateral(address forwardContract, bool fromShort, uint256 amount) external;

    /// @notice Transfers balance between two parties.
    /// @param forwardContract Address of forward contract.
    /// @param shortToLong Bool indicating the direction of transfer.
    /// @param amount Amount to be transfered.
    /// @return amountOwed_ Amount of collateral owed if balance insufficient.
    function transferBalance(address forwardContract, bool shortToLong, uint256 amount) 
        external 
        returns (uint256 amountOwed_);
    
    /// @notice Adjusts balances of both parties according to m-to-m.
    /// @param forwardContract Address of the forward contract
    /// @param contractValueChange Change of value of forward contract during m-t--m
    /// @return owedAmount_ Amount owed by losing party after mToM
    function collateralMToM(address forwardContract, int256 contractValueChange) 
        external 
        returns (uint256 owedAmount_);

    /// @notice Returns collateral to long and short parties.
    /// @param forwardContract Address of the forward contract.
    function returnCollateral(address forwardContract) external;
}