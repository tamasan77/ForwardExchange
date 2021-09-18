// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20Token is ERC20 {

    constructor(uint256 initialSupply) ERC20("Test Token", "TTKN") {
        _mint(msg.sender, initialSupply);
    }
}