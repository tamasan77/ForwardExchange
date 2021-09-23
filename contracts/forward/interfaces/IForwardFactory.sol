// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IForwardFactory interface
interface IForwardFactory {
    event ForwardCreated(string name, bytes32 symbol);

    /// @notice Create forward contract.
    /// @param name Name of forward.
    /// @param symbol Symbol of forward
    /// @param sizeOfContract size of contract to be created
    /// @param expirationDate Date of expiration of contract
    /// @param underlyingApiURL URL of underlying asset
    /// @param underlyingApiPath JSON path to underlying asset's price.
    /// @param underlyingDecimalScale Decimal scale
    /// @return forwardContractAddress_ Address of forward contract.
    function createForwardContract(
        string memory name, 
        bytes32 symbol,
        uint256 sizeOfContract,
        uint256 expirationDate,
        string memory underlyingApiURL,
        string memory underlyingApiPath,
        int256 underlyingDecimalScale
        ) 
        external returns (address forwardContractAddress_);
}