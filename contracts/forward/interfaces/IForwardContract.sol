// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IForwardContract interface
interface IForwardContract {
    event SettledAtExpiration(int256 profitAndLoss);
    event Defaulted(address defaultingParty, uint256 amountSillOwed);
    event MarkedToMarket(int256 contractValueChange, uint256 shortOwedAmount, uint256 longOwedAmount);
    event LinkWithdrawn(uint256 amountWithdrawn);

    /// @notice Initiate forward contract and send link to oracles.
    /// @param _long Long party
    /// @param _short Short party
    /// @param _collateralWallet Address of the collateral wallet
    /// @param _exposureMarginRate Exposure margin rate.
    /// @param _maintenanceMarginRate Maintenance margin rate.
    /// @param _collateralTokenAddress Address of the ERC20 collateral token.
    function initiateForward(
        address _long, 
        address _short,
        address _collateralWallet,
        address _longPersonalWallet,
        address _shortPersonalWallet,
        uint _exposureMarginRate,
        uint _maintenanceMarginRate, 
        address _collateralTokenAddress) 
        external  
        returns (bool initiated_);

    /// @notice Mark to market function that is called periodically to transfer gains/losses
    /// @dev Collateral req. is checked and if party is unable to satisfy collateral requirement by next m-to-m then default.
    function markToMarket() external;

    /// @notice Settle and close contract at expiry.
    function settleAtExpiration() external;

    /// @notice Defaults contract and transfers all collateral of defaulting party to toher party.
    /// @param _defaultingParty Address of the defaulting party
    /// @param amountStillOwed Amount of collateral still owed by lsoing party after defaulting.
    function defaultContract(address _defaultingParty, uint256 amountStillOwed) external;

    /// @notice Withdraw link from forward contract callable by ForwardFactory contract
    function withdrawLinkFromContract() external;

    /// @notice Returns current contract state.
    /// @return Current contract state.
    function getContractState() external view returns(string memory);

    /// @notice get long party
    /// @return address of long party
    function getLong() external view returns (address);
}