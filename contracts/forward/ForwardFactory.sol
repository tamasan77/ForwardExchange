// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/DateTimeLibrary.sol";
import "./ForwardContract.sol";
import "../oracles/link-pool-oracles/LinkPoolValuationOracle.sol";
import "../oracles/link-pool-oracles/USDRFROracle.sol";

contract ForwardFatory {
    address[] public forwardContracts;
    address payable valuationOracleAddres = payable(address(new LinkPoolValuationOracle()));
    address payable usdRiskFreeRateOracleAddress = payable(address(new USDRFROracle()));

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
        external returns (address forwardContractAddress_) {
            require(bytes(underlyingApiURL).length != 0, "url empty");
            require(bytes(underlyingApiPath).length != 0, "url empty");
            require(underlyingDecimalScale != 0, "decimal zero");
            require(sizeOfContract > 0, "contract size zero");
            require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
            forwardContractAddress_ = address(new ForwardContract(
                name, 
                symbol, 
                sizeOfContract, 
                expirationDate,
                underlyingApiURL,
                underlyingApiPath,
                underlyingDecimalScale,
                valuationOracleAddres,
                usdRiskFreeRateOracleAddress));
            require(keccak256(
                abi.encodePacked(ForwardContract(forwardContractAddress_).getContractState()))
                 == keccak256(abi.encodePacked("Created")), "contract not created");
            forwardContracts.push(forwardContractAddress_);
            emit ForwardCreated(name, symbol);
    }
}
