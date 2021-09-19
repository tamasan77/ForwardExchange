// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./CollateralWallet.sol";

/// @title Collateral Wallet Factory
/// @author Tamas An
/// @notice Factory for creating and storing collateral wallets
contract CollateralWalletFactory {
    address[] public collateralWallets;

    event CreatedWallet(string name);

    /// @notice Creates new collateral wallet with given name and owner.
    /// @param _walletName name of wallet
    function createCollateralWallet(string memory _walletName) 
        external
        returns (address collateralWalletAddress_) 
    {
        collateralWalletAddress_ = address(new CollateralWallet(_walletName));
        collateralWallets.push(collateralWalletAddress_);
        emit CreatedWallet(_walletName);
    }

}