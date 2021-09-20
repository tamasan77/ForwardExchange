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

    enum ContractState {Created, Initiated, Settled, Defaulted}
    string public name;
    string public symbol;
    ContractState internal contractState;
    uint256 public sizeOfContract;
    address private long;
    address private short;
    uint256 public initialForwardPrice;
    int256 public annualRiskFreeRate;
    uint256 public expirationDate;
    uint256 public underlyingPrice;//scaled 1/100 ie. 45.07 -> 4507
    //collateral wallets
    address private longWallet;
    address private shortWallet;
    address private collateralTokenAddress;
    //MM(8%) + EM (2%) = IM (10%)
    uint256 public exposureMarginRate;
    uint256 public maintenanceMarginRate;
    uint256 internal prevDayClosingPrice;
    string private underlyingApiURL;
    string public underlyingApiPath;
    int256 public underlyingDecimals;
    address payable valuationOracleAddress;
    address payable underlyingOracleAddress;
    address payable usdRiskFreeRateOracleAddress;
    uint8 internal rfrMaturityTranchIndex;

    constructor(
            string memory _name, 
            string memory _symbol, 
            uint256 _sizeOfContract,
            string memory _underlyingApiURL,
            string memory _underlyingApiPath,
            int256 _underlyingDecimals,
            address payable _valuationOracleAddress
    ) {
        name = _name;
        symbol = _symbol;
        sizeOfContract = _sizeOfContract;
        underlyingApiPath = _underlyingApiPath;
        underlyingApiURL = _underlyingApiURL;
        underlyingDecimals = _underlyingDecimals;
        valuationOracleAddress = _valuationOracleAddress;
        underlyingOracleAddress = payable(address(new LinkPoolUintOracle(underlyingDecimals, underlyingApiURL, underlyingApiPath)));
        usdRiskFreeRateOracleAddress = payable(address(new USDRFROracle()));
        contractState = ContractState.Created;
    }

    /// @notice Initiate forward contract and send link to oracles.
    /// @param _long Long party
    /// @param _short Short party
    /// @param _expirationDate Expiration date of the contract
    /// @param _longWallet Address of the long party's wallet
    /// @param _shortWallet Address of the short party's wallet
    /// @param _exposureMarginRate Exposure margin rate.
    /// @param _maintenanceMarginRate Maintenance margin rate.
    /// @param _collateralTokenAddress Address of the ERC20 collateral token.
    function initiateForward(
        address _long, 
        address _short,
        uint256 _expirationDate,
        address _longWallet, 
        address _shortWallet, 
        uint _exposureMarginRate,
        uint _maintenanceMarginRate, 
        address _collateralTokenAddress) 
        external 
        override 
        returns (bool initiated_) 
    {
        require(_long != address(0), "0 address");
        require(_short != address(0), "0 address");
        require(_long != _short, "same party");
        require(_longWallet != address(0), "0 address");
        require(_shortWallet != address(0), "0 address");
        require(_longWallet != _shortWallet, "same address");
        require(_maintenanceMarginRate != 0, "zero maintenance");
        
        long = _long;
        short = _short;
        expirationDate = _expirationDate;
        longWallet = _longWallet;
        shortWallet = _shortWallet;
        exposureMarginRate = _exposureMarginRate;
        maintenanceMarginRate = _maintenanceMarginRate;
        collateralTokenAddress = _collateralTokenAddress;

        //Fund oracles with link
        LinkTokenInterface linkTokenAddress = LinkTokenInterface(
            LinkPoolValuationOracle(valuationOracleAddress)._linkAddress());
        linkTokenAddress.transfer(
            valuationOracleAddress, 
            ((DateTimeLibrary.diffSeconds(block.timestamp, _expirationDate) / 86400) + 5) * 
                LinkPoolValuationOracle(valuationOracleAddress).fee());
        linkTokenAddress.transfer(
            underlyingOracleAddress, 
            ((DateTimeLibrary.diffSeconds(block.timestamp, _expirationDate) / 86400) + 5) * 
                LinkPoolValuationOracle(valuationOracleAddress).fee());
        linkTokenAddress.transfer(
            usdRiskFreeRateOracleAddress, 
                ((DateTimeLibrary.diffSeconds(block.timestamp, _expirationDate) / 86400) + 5) * 
                    LinkPoolValuationOracle(valuationOracleAddress).fee());

        //Update API path of risk free rate according for maturity of contract.      
        USDRFROracle(usdRiskFreeRateOracleAddress).updateAPIPath(
            int(DateTimeLibrary.diffSeconds(block.timestamp, _expirationDate)));

        //call valuation API to get initialForwardPrice!!!!!!!!!!!!!11
        initialForwardPrice = 0;//this doesn't need to be a parameter, just set it here directly
        prevDayClosingPrice = initialForwardPrice;
        //annualRiskFreeRate = _annualRiskFreeRate;
        //add token to each wallet if not added yet
        //set new balance to zero
        contractState = ContractState.Initiated;
        //emit Initiated(long, short, initialForwardPrice, annualRiskFreeRate, expirationDate, sizeOfContract, exposureMarginRate + maintenanceMarginRate);
        initiated_ = true;
    }

    //request annual risk free rate
    function requestRiskFreeRate() internal {
        USDRFROracle(usdRiskFreeRateOracleAddress).updateAPIPath(int(BokkyPooBahsDateTimeLibrary.diffSeconds(block.timestamp, expirationDate)));
        USDRFROracle(usdRiskFreeRateOracleAddress).requestIndexPrice("");//do I add my API key here??
    }

    //set annual risk free rate once job is fulfilled
    function setRiskFreeRate() internal {
        annualRiskFreeRate = USDRFROracle(usdRiskFreeRateOracleAddress).getSignedResult();
    }

    //request underlying price
    function requestUnderlyingPrice() internal {
        LinkPoolUintOracle(underlyingOracleAddress).requestIndexPrice("");
    }

    //set underlying price once job is fulfilled
    function setUnderlyingPrice() internal  view{
        LinkPoolUintOracle(underlyingOracleAddress).getUnsignedResult();
    }

    //request forward price
    function requestForwardPrice() internal {
        LinkPoolValuationOracle(valuationOracleAddress).requestIndexPrice(concetenateStringsForURL(uint2str(underlyingPrice), int2str(annualRiskFreeRate), uint2str(block.timestamp), uint2str(expirationDate)));
    }

    //set forward price once job is fulfilled
    function getForwardPrice() internal view returns(uint256){
        return LinkPoolValuationOracle(valuationOracleAddress).getUnsignedResult();
    }

}
