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
        forwardContracts.push(forwardContract);
        forwardToCollateral[forwardContract] = collateralToken;
        forwardToShortWallet[forwardContract] = shortPersonalWallet;
        forwardToLongWallet[forwardContract] = longPersonalWallet;
        IERC20(collateralToken).transferFrom(shortPersonalWallet, address(this), collateralAmount);
        IERC20(collateralToken).transferFrom(longPersonalWallet, address(this), collateralAmount);
        forwardToShortBalance[forwardContract] = collateralAmount;
        forwardToLongBalance[forwardContract] = collateralAmount;
    }

    /// @notice Adjusts balances of both parties according to m-to-m.
    /// @param forwardContract Address of the forward contract
    /// @param contractValueChange Change of value of forward contract during m-t--m
    /// @return owedAmount_ Amount owed by losing party after mToM
    function collateralMToM(address forwardContract, int256 contractValueChange) 
        external 
        returns (uint256 owedAmount_){
        uint256 oldShortBalance = forwardToShortBalance[forwardContract];
        uint256 oldLongBalance = forwardToLongBalance[forwardContract];
        owedAmount_ = 0;
        if (contractValueChange > 0) {
            if (oldShortBalance >= uint256(contractValueChange)) {
                forwardToShortBalance[forwardContract] = oldShortBalance - 
                    uint256(contractValueChange);
                forwardToLongBalance[forwardContract] = oldLongBalance + 
                    uint256(contractValueChange);
            } else {
                forwardToShortBalance[forwardContract] = 0;
                forwardToLongBalance[forwardContract] = oldLongBalance + oldShortBalance;
                owedAmount_ = uint256(contractValueChange) - oldShortBalance;
            }
        }
        if (contractValueChange < 0) {
            if (oldLongBalance >= uint256(-contractValueChange)) {
                forwardToShortBalance[forwardContract] = oldShortBalance + 
                    uint256(-contractValueChange);
                forwardToLongBalance[forwardContract] = oldLongBalance - 
                    uint256(-contractValueChange);
            } else {
                forwardToLongBalance[forwardContract] = 0;
                forwardToShortBalance[forwardContract] = oldShortBalance + oldLongBalance;
                owedAmount_ = uint256(-contractValueChange) - oldLongBalance;
            }
        }
    }

    /// @notice Returns collateral to long and short parties.
    /// @param forwardContract Address of the forward contract.
    function returnCollateral(address forwardContract) external {
        IERC20(forwardToCollateral[forwardContract]).transfer(forwardToLongWallet[forwardContract],
            forwardToLongBalance[forwardContract]);
        IERC20(forwardToCollateral[forwardContract]).transfer(forwardToShortWallet[forwardContract],
            forwardToShortBalance[forwardContract]);

    }

}