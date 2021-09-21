// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Collateral Wallet
/// @author Tamas An
/// @notice Wallet for holding ERC20 tokens that can be transferred to collateral wallet.
contract PersonalWallet is Pausable, Ownable {
    using SafeERC20 for IERC20;
    address[] public tokens;
    mapping(address => bool) public containsTokens;

    /// @notice Adds new token ot the tokens array if it is not part of the array yet.
    /// @dev Use containsToken mapping to check if array already contains element or not.
    /// @param newToken Address of the new token to be added
    function addNewToken(address newToken) public onlyOwner {
        if (!containsTokens[newToken]) {
            tokens.push(newToken);
        }
    }
}