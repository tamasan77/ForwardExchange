// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

interface IChainlinkOracle {
    event RequestSent(address oracleAddress, bytes32 jobId, uint256 fee);
    event Fulfilled(bytes32 requestId);
    event LinkWithdrawn(address withdrawer, uint256 amount);
    event Received(address sender, uint256 amount);

    function requestIndexPrice(string memory apiURL) external returns (bytes32 requestId);
    function fulfillSigned(bytes32 _requestId, int256 _price) external;
    function fulfillUnsigned(bytes32 _requestId, uint256 _price) external;
    function withdrawLink() external;
}