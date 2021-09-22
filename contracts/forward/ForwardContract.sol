// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/DateTimeLibrary.sol";
import "../utils/StringManipLibrary.sol";
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
    address public collateralWallet;
    address private collateralTokenAddress;
    address private longPersonalWallet;
    address private shortPersonalWallet;
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
    bool internal marginCallIssuedToShort;
    bool internal marginCallIssuedToLong;

    event SettledAtExpiration(int256 profitAndLoss);
    event Defaulted(address defaultingParty);

    constructor(
            string memory _name, 
            string memory _symbol, 
            uint256 _sizeOfContract,
            uint256 _expirationDate,
            string memory _underlyingApiURL,
            string memory _underlyingApiPath,
            int256 _underlyingDecimals,
            address payable _valuationOracleAddress,
            address _usdRiskFreeRateOracleAddress
    ) {
        name = _name;
        symbol = _symbol;
        sizeOfContract = _sizeOfContract;
        expirationDate = _expirationDate;
        underlyingApiPath = _underlyingApiPath;
        underlyingApiURL = _underlyingApiURL;
        underlyingDecimals = _underlyingDecimals;
        valuationOracleAddress = _valuationOracleAddress;
        usdRiskFreeRateOracleAddress = _usdRiskFreeRateOracleAddress;
        underlyingOracleAddress = payable(address(new LinkPoolUintOracle(
            underlyingDecimals, underlyingApiURL, underlyingApiPath)));
        //Update API path of risk free rate according to maturity of contract.      
        USDRFROracle(usdRiskFreeRateOracleAddress).updateAPIPath(
            int(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate)));
        //Fund oracles with link
        LinkTokenInterface linkTokenAddress = LinkTokenInterface(
            LinkPoolValuationOracle(valuationOracleAddress)._linkAddress());
        linkTokenAddress.transfer(
            valuationOracleAddress, 
            ((DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) / 86400) + 5) * 
                LinkPoolValuationOracle(valuationOracleAddress).fee());
        linkTokenAddress.transfer(
            underlyingOracleAddress, 
            ((DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) / 86400) + 5) * 
                LinkPoolUintOracle(valuationOracleAddress).fee());
        linkTokenAddress.transfer(
            usdRiskFreeRateOracleAddress, 
            ((DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) / 86400) + 5) * 
                USDRFROracle(valuationOracleAddress).fee());
        contractState = ContractState.Created;
    }

    // a few minutes before calling this function one should call the following functions:
    // requestRiskFreeRate()
    // requestUnderlyingPrice()
    // requestForwardPrice()
    //because of this a few minutes need to elapse between the creation of forward contracts and initiation
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
        override 
        returns (bool initiated_) 
    {
        require(_long != address(0), "0 address");
        require(_short != address(0), "0 address");
        require(_long != _short, "same party");
        require(_collateralWallet != address(0), "0 address");
        require(_longPersonalWallet != address(0), "0 address");
        require(_shortPersonalWallet != address(0), "0 address");
        require(_maintenanceMarginRate != 0, "zero maintenance");
        initialForwardPrice = LinkPoolValuationOracle(valuationOracleAddress).unsignedResult();
        prevDayClosingPrice = initialForwardPrice;
        long = _long;
        short = _short;
        collateralWallet = _collateralWallet;
        longPersonalWallet = _longPersonalWallet;
        shortPersonalWallet = _shortPersonalWallet;
        exposureMarginRate = _exposureMarginRate;
        maintenanceMarginRate = _maintenanceMarginRate;
        collateralTokenAddress = _collateralTokenAddress;
        marginCallIssuedToLong = false;
        marginCallIssuedToShort = false;
        uint256 initialCollateralRequirement = initialForwardPrice * 
            ((maintenanceMarginRate + exposureMarginRate) / 10000);
        // At this point the personal wallets must have approved the collateral wallet
        // to transfer given collateral.
        CollateralWallet(collateralWallet).setupInitialCollateral(
            address(this), shortPersonalWallet, longPersonalWallet, 
            collateralTokenAddress, initialCollateralRequirement);
        contractState = ContractState.Initiated;
        //emit Initiated(long, short, initialForwardPrice, annualRiskFreeRate, expirationDate, sizeOfContract, exposureMarginRate + maintenanceMarginRate);
        initiated_ = true;
    }

    /// @notice Make a request for risk free rate. Takes 2-3 min. to fulffill.
    /// @dev result should be available in 2-3 min.
    function requestRiskFreeRate() internal {
        USDRFROracle(usdRiskFreeRateOracleAddress).updateAPIPath(int(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate)));
        USDRFROracle(usdRiskFreeRateOracleAddress).requestIndexPrice("");//do I add my API key here??
    }

    /// @notice Make a request underlying price. Takes 2-3 min. to fulffill.
    /// @dev result should be available in 2-3 min.
    function requestUnderlyingPrice() internal {
        LinkPoolUintOracle(underlyingOracleAddress).requestIndexPrice("");
    }

    uint256 internal timeForwardPriceRequested;
    /// @notice Make a request for price of the forward. Takes 2-3 min. to fulffill.
    /// @dev result should be available in 2-3 min.
    function requestForwardPrice() internal {
        /// we needed to request underlying price and annual risk free rate beforehand
        underlyingPrice = LinkPoolUintOracle(underlyingOracleAddress).unsignedResult();
        annualRiskFreeRate = USDRFROracle(usdRiskFreeRateOracleAddress).signedResult();
        LinkPoolValuationOracle(valuationOracleAddress).requestIndexPrice(
            StringManipLibrary.concatenateStringsForURL(
                StringManipLibrary.uint2str(underlyingPrice), 
                StringManipLibrary.int2str(annualRiskFreeRate), 
                StringManipLibrary.uint2str(block.timestamp), 
                StringManipLibrary.uint2str(expirationDate)));
        timeForwardPriceRequested = block.timestamp;
    }

    /// @notice Mark to market function that is called periodically to transfer gains/losses
    /// @dev Collateral req. is checked and if party is unable to satisfy collateral requirement by next m-to-m then default.
    function markToMarket() external {
        require(contractState == ContractState.Initiated, 
                "Contract not initiated");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        require(DateTimeLibrary.diffSeconds(timeForwardPriceRequested, block.timestamp) > 300,
            "mtom early err");
        uint256 currentForwardPrice = 
            LinkPoolValuationOracle(valuationOracleAddress).unsignedResult();
        uint256 newContractValue = currentForwardPrice * sizeOfContract;
        uint256 oldContractValue = prevDayClosingPrice * sizeOfContract;
        int256 contractValueChange = int256(newContractValue) - int256(oldContractValue);
        uint256 newMarginRequirement = newContractValue * (maintenanceMarginRate / 10000);
        //In this case the amount to be transfered is in cents, not dollars due to 1:100 scaling
        uint256 owedAmount = CollateralWallet(collateralWallet).collateralMToM(address(this), 
            contractValueChange);
        if (contractValueChange > 0) {
            if (owedAmount > 0) {

            }
        }
        if (CollateralWallet(collateralWallet).forwardToShortBalance(
            address(this)) < newMarginRequirement) 
        {
            if (marginCallIssuedToShort) {
                defaultContract(short);
            } else {
                marginCallIssuedToShort = true;
            }
        } else {
            marginCallIssuedToShort = false;
        }

        if (CollateralWallet(collateralWallet).forwardToLongBalance(
            address(this)) < newMarginRequirement) 
        {
            if (marginCallIssuedToLong) {
                defaultContract(long);
            } else {
                marginCallIssuedToLong = true;
            }
        } else {
            marginCallIssuedToLong = false;
        }



        prevDayClosingPrice = currentForwardPrice;
        
        //emit MarkedToMarket(block.timestamp, contractValueChange, long, short);
    }

    /// @notice Settle and close contract at expiry.
    /// 
    function settleAtExpiration() external {
        require(contractState == ContractState.Initiated, "wrong state");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        uint256 initialContractValue = initialForwardPrice * sizeOfContract;
        uint256 finalContractValue = prevDayClosingPrice * sizeOfContract;
        int profitAndLoss = int256(finalContractValue) - int256(initialContractValue);
        contractState = ContractState.Settled;
        emit SettledAtExpiration(profitAndLoss);
    }

    function defaultContract(address _defaultingParty) public {
        require(((_defaultingParty == short) || (_defaultingParty == long)), "party err");
        require(contractState == ContractState.Initiated, "state err");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0, "exp date err");
        
        if (_defaultingParty == short) {
            transferCollateralFrom(shortWallet, longWallet, CollateralWallet(shortWallet).getMappedBalance(address(this), collateralTokenAddress), collateralTokenAddress);
        } else {
            transferCollateralFrom(longWallet, shortWallet, CollateralWallet(longWallet).getMappedBalance(address(this), collateralTokenAddress), collateralTokenAddress);
        }
        //change contract state and emit event
        contractState = ContractState.Defaulted;
        emit Defaulted(_defaultingParty);
    }

    function getLong() external view returns (address) {
            return long;
    }
    function getShort() external view returns (address) {
            return short;
    }

    function getLongPersonalWallet() external view returns (address) {
        return longPersonalWallet;
    }

    function getShortPersonalWallet() external view returns (address) {
        return shortPersonalWallet;
    }

}
