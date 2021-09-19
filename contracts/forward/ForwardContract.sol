// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/DateTimeLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IForwardContract.sol";
import "../collateral-wallet/CollateralWallet.sol";
import "../oracles/link-pool-oracles/LinkPoolValuationOracle.sol";
import "../oracles/link-pool-oracles/LinkPoolUintOracle.sol";
import "../oracles/link-pool-oracles/USDRFROracle.sol";

/// @title Forward Contract
/// @author Tamas An
/// @notice Forward Contract with all relevant functionalities.
contract ForwardContract is IForwardContract{
    using SafeERC20 for IERC20;

}
