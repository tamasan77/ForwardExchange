// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title IChainlinkOracle interface
interface IChainlinkOracle {
    event LinkWithdrawn(address withdrawer, uint256 amount);
    event Received(address sender, uint256 amount);

    /// @notice Create Chainlink request with uint256 job.
    /// @dev For underlying price oracle apiURLParameters is empty string.
    /// @param apiURLParameters Parameters added to API URL.
    /// @return requestId The ID of the request
    function requestIndexPrice(string memory apiURLParameters)
        external
        returns (bytes32 requestId);

    /// @notice Receive response in the form of int256.
    /// @dev It may take up to 3-4 minutes for the job to be fulffilled.
    /// @param _requestId ID of the request.
    /// @param _result Result of GET request.
    function fulfillSigned(bytes32 _requestId, int256 _result) external;

    /// @notice Receive response in the form of uint256.
    /// @dev It may take up to 3-4 minutes for the job to be fulffilled.
    /// @param _requestId ID of the request.
    /// @param _result Result of GET request.
    function fulfillUnsigned(bytes32 _requestId, uint256 _result) external;

    /// @notice Allows the owner to withdraw the LINK in this contract.
    /// @dev Withdraw LINK after the forward contract is settled.
    function withdrawLink() external;
}