// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ERC20 token for testing
/// @author Tamas An
/// @notice ERC20 Token used for testing collateral wallet.
contract TestERC20Token is ERC20 {
    constructor(uint256 initialSupply) ERC20("Test Token", "TTKN") {
        _mint(msg.sender, initialSupply);
    }
}