// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title ICollateralWalletFactory interface
interface ICollateralWalletFactory {
    event CreatedWallet(string name);

    /// @notice Creates new collateral wallet with given name and owner.
    /// @param _walletName name of wallet
    /// @return collateralWalletAddress_ Address of collateral wallet
    function createCollateralWallet(string memory _walletName) 
        external
        returns (address collateralWalletAddress_);
}