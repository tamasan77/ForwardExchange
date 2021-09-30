// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./PersonalWallet.sol";
import "./interfaces/IPersonalWalletFactory.sol";

/// @title Personal wallet factory
/// @author Tamas An
/// @notice Factory that creates and holds addresses of personal wallets.
contract PersonalWalletFactory is IPersonalWalletFactory{
    address[] public personalWallets;

    /// @notice Creates Personal Wallet
    /// @param walletOwner Address of the owner of the wallet
    /// @param walletName Name of the wallet
    function createPersonalWallet(address walletOwner, string memory walletName) 
        external 
        override
    {
        require(bytes(walletName).length != 0, "name empty");
        address personalWallet_ = address(new PersonalWallet(walletName,walletOwner));
        personalWallets.push(personalWallet_);
        emit WalletCreated(walletOwner, personalWallet_);
    }
}