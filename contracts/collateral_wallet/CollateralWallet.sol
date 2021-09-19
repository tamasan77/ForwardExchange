// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Collateral Wallet
/// @author Tamas An
/// @notice Wallet for holding ERC20 tokens as collateral.
contract CollateralWallet is Pausable, Ownable{
    using SafeERC20 for IERC20;
    IERC20[] public tokens;
    mapping(address => bool) public containsTokens;
    string public walletName;
    mapping(address => mapping(address => uint256)) private forwardToCollateralMapping;
    //mapping(address => mapping(address => uint256)) private pledgedCollateralToForwardMapping;
    mapping(address => mapping(address => address)) private forwardCollateralToOwnerMapping;
    
    event CollateralReturned(address collateralOwner, uint256 remainingBalance);

    constructor (string memory _walletName) {
        walletName = _walletName;
    }

    /// @notice Sets new balance for given collateral token corresponding to given forward contract.
    /// @param forwardContractAddress Address of forward contract for collateral.
    /// @param collateralTokenAddress Address of collateral token.
    /// @param newBalance value to set balance to
    function setNewBalance(
        address forwardContractAddress, 
        address collateralTokenAddress, 
        uint256 newBalance) 
        external 
    {
        require(forwardContractAddress != address(0), "0 address");
        require(collateralTokenAddress != address(0), "0 address");
        forwardToCollateralMapping[forwardContractAddress][collateralTokenAddress] = newBalance;
        //pledgedCollateralToForwardMapping[collateralTokenAddress][forwardContractAddress] = newBalance;
    }

    /// @notice Gets balance of given collateral token corresponding to given forward contract.
    /// @param forwardContractAddress Address of forward contract for collateral.
    /// @param collateralTokenAddress Address of collateral token.
    /// @return Balance.
    function getMappedBalance(address forwardContractAddress, address collateralTokenAddress) 
        external 
        view 
        returns (uint256) 
    {
        require(forwardContractAddress != address(0), "0 address");
        require(collateralTokenAddress != address(0), "0 address");
        return forwardToCollateralMapping[forwardContractAddress][collateralTokenAddress];
    }

    /// @notice Approve given spender with spending given amount of given token.
    /// @param collateralTokenAddress Address of collateral token
    /// @param spender Address of spender to be approved
    /// @param amount to be approved
    function approveSpender(address collateralTokenAddress, address spender, uint256 amount) 
        external 
    {
        require(spender != address(0), "0 address");
        require(collateralTokenAddress != address(0), "0 address");
        IERC20(collateralTokenAddress).approve(spender, amount);
    }

    function returnCollateral(address forwardContractAddress, address collateralTokenAddress) 
        external 
    {
        address collateralOwner = forwardCollateralToOwnerMapping[forwardContractAddress]
            [collateralTokenAddress];
        uint256 remainingBalance = forwardToCollateralMapping[forwardContractAddress][collateralTokenAddress];
        IERC20(collateralTokenAddress).approve(forwardContractAddress, 0);
        IERC20(collateralTokenAddress).transfer(collateralOwner, remainingBalance);
        emit CollateralReturned(collateralOwner, remainingBalance);
    }

}