// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
import "./PersonalWallet.sol";

/// @title Personal wallet factory
/// @author Tamas An
/// @notice Factory that creates and holds addresses of personal wallets.
contract PersonalWalletFactory {
    address[] public personalWallets;

    event WalletCreated(address walletOwner);

    /// @notice Creates Personal Wallet
    /// @param walletOwner Address of the owner of the wallet
    /// @param walletName Name of the wallet
    /// @return personalWallet_ Address of the newly created wallet.
    function createPersonalWallet(address walletOwner, string memory walletName) 
        external 
        returns (address personalWallet_) 
    {
        require(bytes(walletName).length != 0, "name empty");
        personalWallet_ = address(new PersonalWallet(walletName,walletOwner));
        personalWallets.push(personalWallet_);
        emit WalletCreated(walletOwner);
    }
}