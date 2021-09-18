// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./CollateralWallet.sol";

/// @title Collateral Wallet Factory
/// @author Tamas An
/// @notice Factory for creating and storing collateral wallets
contract CollateralWalletFactory {
    address[] public collateralWallets;
    mapping(address => address) ownerToWallet;

    event CreatedWallet(string name, address owner);

    function createCollateralWallet(string memory _walletName, address _owner) 
        external
        returns (address collateralWalletAddress_) 
    {
        require(_owner != address(0), "0 address");
        collateralWalletAddress_ = address();
    }

}