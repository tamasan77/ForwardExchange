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
    address[] public tokens;
    mapping(address => bool) public containsTokens;
    address[] public forwardContracts;
    string public walletName;
    mapping(address => address) public forwardToCollateral;
    mapping(address => uint256) public forwardToShortBalance;
    mapping(address => uint256) public forwardToLongBalance;
    mapping(address => address) internal forwardToShortWallet;
    mapping(address => address) internal forwardToLongWallet;
    
    event CollateralReturned(address collateralOwner, uint256 remainingBalance);

    constructor (string memory _walletName) {
        walletName = _walletName;
    }

    /// @notice Transfers initial collateral requirements from personal wallets to this wallet.
    /// @param forwardContract Address of forward contract
    /// @param shortPersonalWallet Personal wallet of short party
    /// @param longPersonalWallet Personal wallet of long party
    /// @param collateralToken Address of collateral token.
    /// @param collateralAmount Amount of collateral to be transfered
    function setupInitialCollateral (
        address forwardContract,
        address shortPersonalWallet,
        address longPersonalWallet,
        address collateralToken,
        uint256 collateralAmount
    ) external 
    {   
        if (!containsTokens[collateralToken]) {
            tokens.push(collateralToken);
            containsTokens[collateralToken] = true;
        }
        forwardContracts.push(forwardContract);
        forwardToCollateral[forwardContract] = collateralToken;
        forwardToShortWallet[forwardContract] = shortPersonalWallet;
        forwardToLongWallet[forwardContract] = longPersonalWallet;
        IERC20(collateralToken).transferFrom(shortPersonalWallet, address(this), collateralAmount);
        IERC20(collateralToken).transferFrom(longPersonalWallet, address(this), collateralAmount);
        forwardToShortBalance[forwardContract] = collateralAmount;
        forwardToLongBalance[forwardContract] = collateralAmount;
    }

    // Personal wallet should have approved collateral before calling add collateral
    /// @notice Transfers collateral from personal wallet to collateral wallet.
    /// @param forwardContract Address of the forward contract.
    /// @param fromShort Bool whether collateral is from short or long party of forward contract.
    /// @param amount Amount of collateral to be transfered from personal wallet.
    function addCollateral(address forwardContract, bool fromShort, uint256 amount) external {
        address collateralTokenAddress = forwardToCollateral[forwardContract];
        if(fromShort) {//short adds collateral
            address shortPersonalWallet = forwardToShortWallet[forwardContract];
            require(IERC20(collateralTokenAddress).allowance(
                shortPersonalWallet, address(this)) > amount, "allowance err");
            IERC20(collateralTokenAddress).transferFrom(
                shortPersonalWallet, address(this), amount);
            uint256 oldShortBalance = forwardToShortBalance[forwardContract];
            forwardToShortBalance[forwardContract] = oldShortBalance + amount;
        } else {//long adds collateral
            address longPersonalWallet = forwardToLongWallet[forwardContract];
            require(IERC20(collateralTokenAddress).allowance(
                longPersonalWallet, address(this)) > amount, "allowance err");
            IERC20(collateralTokenAddress).transferFrom(
                longPersonalWallet, address(this), amount);
            uint256 oldLongBalance = forwardToLongBalance[forwardContract];
            forwardToLongBalance[forwardContract] = oldLongBalance + amount;
        }
    }

    /// @notice Transfers balance between two parties.
    /// @param forwardContract Address of forward contract.
    /// @param shortToLong Bool indicating the direction of transfer.
    /// @param amount Amount to be transfered.
    /// @return amountOwed_ Amount of collateral owed if balance insufficient.
    function transferBalance(address forwardContract, bool shortToLong, uint256 amount) public returns (uint256 amountOwed_){
        uint256 oldShortBalance = forwardToShortBalance[forwardContract];
        uint256 oldLongBalance = forwardToLongBalance[forwardContract];
        amountOwed_ = 0;
        if (shortToLong) {
            if (oldShortBalance >= amount) {
                forwardToShortBalance[forwardContract] = oldShortBalance - amount;
                forwardToLongBalance[forwardContract] = oldLongBalance + amount;
            } else {
                forwardToShortBalance[forwardContract] = 0;
                forwardToLongBalance[forwardContract] = oldLongBalance + oldShortBalance;
                amountOwed_ = amount - oldShortBalance;
            }
        } else {
            if (oldLongBalance >= amount) {
                forwardToLongBalance[forwardContract] = oldLongBalance - amount;
                forwardToShortBalance[forwardContract] = oldShortBalance + amount;
            } else {
                forwardToLongBalance[forwardContract] = 0;
                forwardToShortBalance[forwardContract] = oldShortBalance + oldLongBalance;
                amountOwed_ = amount - oldLongBalance;
            }
        }
    }

    /// @notice Adjusts balances of both parties according to m-to-m.
    /// @param forwardContract Address of the forward contract
    /// @param contractValueChange Change of value of forward contract during m-t--m
    /// @return owedAmount_ Amount owed by losing party after mToM
    function collateralMToM(address forwardContract, int256 contractValueChange) 
        external 
        returns (uint256 owedAmount_){
        owedAmount_ = 0;
        if (contractValueChange > 0) {
            owedAmount_ = transferBalance(forwardContract, true, uint256(contractValueChange));
        }
        if (contractValueChange < 0) {
            owedAmount_ = transferBalance(forwardContract, false, uint256(-contractValueChange));
        }
    }

    /// @notice Returns collateral to long and short parties.
    /// @param forwardContract Address of the forward contract.
    function returnCollateral(address forwardContract) external {
        IERC20(forwardToCollateral[forwardContract]).transfer(forwardToLongWallet[forwardContract],
            forwardToLongBalance[forwardContract]);
        forwardToLongBalance[forwardContract] = 0;
        IERC20(forwardToCollateral[forwardContract]).transfer(forwardToShortWallet[forwardContract],
            forwardToShortBalance[forwardContract]);
        forwardToShortBalance[forwardContract] = 0;
    }

}