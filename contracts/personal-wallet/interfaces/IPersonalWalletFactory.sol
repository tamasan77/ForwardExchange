// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IPersonalWalletFactory interface
interface IPersonalWalletFactory {
    event WalletCreated(address walletOwner);

    /// @notice Creates Personal Wallet
    /// @param walletOwner Address of the owner of the wallet
    /// @param walletName Name of the wallet
    /// @return personalWallet_ Address of the newly created wallet.
    function createPersonalWallet(address walletOwner, string memory walletName) 
        external 
        returns (address personalWallet_);
}