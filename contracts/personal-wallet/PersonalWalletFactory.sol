// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
import "./PersonalWallet.sol";

contract PersonalWalletFactory {
    address[] public personalWallets;

    event WalletCreated(address walletOwner);

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