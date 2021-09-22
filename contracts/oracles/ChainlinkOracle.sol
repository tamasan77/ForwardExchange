// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IChainlinkOracle.sol";

/// @title Chainlink Oracle
/// @author Tamas An
/// @notice This contract is used to make HTTP GET request to external API
/// @dev Based on official chainlink documentation
contract ChainlinkOracle is ChainlinkClient, Ownable,  IChainlinkOracle{
    using Chainlink for Chainlink.Request;

    bool public isSignedResult;
    uint256 public unsignedResult;
    int256 public signedResult;
    address public oracleAddress;
    bytes32 public jobId;
    string internal apiPath;
    string private apiBaseURL;
    int256 public decimals;
    uint256 public fee;

    constructor(
        address _oracleAddress, 
        bytes32 _jobId, 
        address linkAddress, 
        uint256 _fee, 
        int256 _decimals, 
        string memory _apiBaseURL,
        string memory _apiPath, 
        bool _isSignedResult) 
    {
        if (linkAddress == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(linkAddress);
        }
        oracleAddress = _oracleAddress;
        jobId = _jobId;
        fee = _fee;
        decimals = _decimals;
        apiBaseURL = _apiBaseURL;
        apiPath = _apiPath;
        isSignedResult = _isSignedResult;
    }

    /// @notice Receives ETH.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev Lets contract hadle function calls dynamically. For future expendability.
    fallback () external payable {

    }

    /// @notice Create Chainlink request with uint256 job.
    /// @dev For underlying price oracle apiURLParameters is empty string.
    /// @param apiURLParameters Parameters added to API URL.
    /// @return requestId The ID of the request
    function requestIndexPrice(string memory apiURLParameters)
        external
        override
        returns (bytes32 requestId)
    {
        Chainlink.Request memory request;
        if (isSignedResult) {
            request = buildChainlinkRequest(jobId, address(this), this.fulfillSigned.selector);
        } else {
            request = buildChainlinkRequest(jobId, address(this), this.fulfillUnsigned.selector);
        }
        request.add("get", concetenateTwoStrings(apiBaseURL, apiURLParameters));
        request.add("path", apiPath);
        request.addInt("times", decimals);
        //ChainlinkRequested(bytes32 indexd id) is emitted
        requestId = sendChainlinkRequestTo(oracleAddress, request, fee);
    }

    /// @notice Receive response in the form of int256.
    /// @dev It may take up to 3-4 minutes for the job to be fulffilled.
    /// @param _requestId ID of the request.
    /// @param _result Result of GET request.
    function fulfillSigned(bytes32 _requestId, int256 _result) 
        external 
        override 
        recordChainlinkFulfillment(_requestId)
    {
        //emits ChainlinkFullfilled(bytes32 indexd id) event
        signedResult = _result;
    }

    /// @notice Receive response in the form of uint256.
    /// @dev It may take up to 3-4 minutes for the job to be fulffilled.
    /// @param _requestId ID of the request.
    /// @param _result Result of GET request.
    function fulfillUnsigned(bytes32 _requestId, uint256 _result) 
        external 
        override
        recordChainlinkFulfillment(_requestId)
    {
        //emits ChainlinkFullfilled(bytes32 indexd id) event
        unsignedResult = _result;
    }


    /// @notice Allows the owner to withdraw the LINK in this contract.
    /// @dev Withdraw LINK after the forward contract is settled.
    function withdrawLink() external override onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        uint256 linkBalance = link.balanceOf(address(this));
        require(link.transfer(msg.sender, linkBalance), "Withdraw err.");
        emit LinkWithdrawn(msg.sender, linkBalance);
    }

    /// @notice Concetenates two strings into single string
    /// @param a First string
    /// @param b Second string
    /// @return Resulting string
    function concetenateTwoStrings(string memory a, string memory b) 
        internal
        pure 
        returns(string memory) 
    {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Sets the API path.
    /// @param newAPIPath New API path to be set.
    function setAPIPath(string memory newAPIPath) internal {
        apiPath = newAPIPath;
    }

    /*
    function getUnsignedResult() external view returns (uint256) {
        return unsignedResult;
    }

    function getSignedResult() external view returns (int256) {
        return signedResult;
    }*/
}

