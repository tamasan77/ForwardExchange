// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title ICollateralWalletFactory interface
interface ICollateralWalletFactory {
    event CreatedWallet(string name, address newWalletAddress);

    /// @notice Creates new collateral wallet with given name and owner.
    /// @param _walletName name of wallet
    function createCollateralWallet(string memory _walletName) external;
}