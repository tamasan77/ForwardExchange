// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IPersonalWalletFactory interface
interface IPersonalWalletFactory {
    event WalletCreated(address walletOwner, address newPersonalWalletAddress);

    /// @notice Creates Personal Wallet
    /// @param walletOwner Address of the owner of the wallet
    /// @param walletName Name of the wallet
    function createPersonalWallet(address walletOwner, string memory walletName) external;
}