// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/DateTimeLibrary.sol";
import "../utils/StringManipLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IForwardContract.sol";
import "../collateral-wallet/CollateralWallet.sol";
import "../oracles/link-pool-oracles/LinkPoolValuationOracle.sol";
import "../oracles/link-pool-oracles/LinkPoolUintOracle.sol";
import "../oracles/link-pool-oracles/USDRFROracle.sol";

/// @title Forward Contract
/// @author Tamas An
/// @notice Forward Contract with all relevant functionalities.
contract ForwardContract is IForwardContract, ChainlinkClient, Ownable{
    using SafeERC20 for IERC20;
    using Chainlink for Chainlink.Request;
    enum ContractState {Created, Initiated, Settled, Defaulted}
    string public name;
    bytes32 public symbol;
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
    address internal longPersonalWallet;
    address internal shortPersonalWallet;
    uint256 public exposureMarginRate;
    uint256 public maintenanceMarginRate;
    uint256 internal prevDayClosingPrice;
    address payable valuationOracleAddress;
    address payable underlyingOracleAddress;
    address payable usdRiskFreeRateOracleAddress;
    uint8 internal rfrMaturityTranchIndex;
    bool internal marginCallIssuedToShort;
    bool internal marginCallIssuedToLong;
    uint256 internal additionalOwedAmount;

    constructor(
            string memory _name, 
            bytes32 _symbol, 
            uint256 _sizeOfContract,
            uint256 _expirationDate,
            string memory _underlyingApiURL,
            string memory _underlyingApiPath,
            int256 _underlyingDecimalScale,
            address payable _valuationOracleAddress,
            address payable _usdRiskFreeRateOracleAddress
    ) 
    {
        name = _name;
        symbol = _symbol;
        sizeOfContract = _sizeOfContract;
        expirationDate = _expirationDate;
        valuationOracleAddress = _valuationOracleAddress;
        usdRiskFreeRateOracleAddress = _usdRiskFreeRateOracleAddress;
        underlyingOracleAddress = payable(address(new LinkPoolUintOracle(
            _underlyingDecimalScale, _underlyingApiURL, _underlyingApiPath)));
        /*
        //Update API path of risk free rate according to maturity of contract.    
        USDRFROracle(usdRiskFreeRateOracleAddress).updateAPIPath(
            int(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate)));*/
        /*
        //Fund oracles with link
        LinkTokenInterface linkTokenAddress = LinkTokenInterface(
            LinkPoolValuationOracle(valuationOracleAddress)._linkAddress());//Link address on kovan
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
                USDRFROracle(valuationOracleAddress).fee());*/
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
    /// @param _longPersonalWallet Address of the long party's personal wallet
    /// @param _shortPersonalWallet Address of the short party's personal wallet
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
        additionalOwedAmount = 0;
        uint256 initialCollateralRequirement = initialForwardPrice * 
            ((maintenanceMarginRate + exposureMarginRate) / 10000);
        // At this point the personal wallets must have approved the collateral wallet
        // to transfer given collateral.
        require(
            (IERC20(collateralTokenAddress).allowance(
                longPersonalWallet, collateralWallet) > initialCollateralRequirement) && 
            (IERC20(collateralTokenAddress).allowance(
                shortPersonalWallet, collateralWallet) > initialCollateralRequirement), 
            "allowance err");
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
    function markToMarket() external override {
        require(contractState == ContractState.Initiated, 
                "Contract not initiated");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        require(DateTimeLibrary.diffSeconds(timeForwardPriceRequested, block.timestamp) > 300,
            "mtom early err");
        if (additionalOwedAmount > 0) {
            if (marginCallIssuedToShort) {
                uint256 amountStillOwed = CollateralWallet(collateralWallet).transferBalance(
                    address(this), true, additionalOwedAmount);
                if (amountStillOwed >  0) {
                    defaultContract(short, amountStillOwed);
                } else {
                    additionalOwedAmount = 0;
                }
            } else if (marginCallIssuedToLong) {
                uint256 amountStillOwed = CollateralWallet(collateralWallet).transferBalance(
                    address(this), false, additionalOwedAmount);
                if (amountStillOwed >  0) {
                    defaultContract(long, amountStillOwed);
                } else {
                    additionalOwedAmount = 0;
                }
            } else {
                revert("mToM err");
            }
        }
        uint256 currentForwardPrice = 
            LinkPoolValuationOracle(valuationOracleAddress).unsignedResult();
        uint256 newContractValue = currentForwardPrice * sizeOfContract;
        uint256 oldContractValue = prevDayClosingPrice * sizeOfContract;
        int256 contractValueChange = int256(newContractValue) - int256(oldContractValue);
        uint256 newMarginRequirement = newContractValue * (maintenanceMarginRate / 10000);
        uint256 shortAmountOwed = 0;
        uint256 longAmountOwed = 0;
        //In this case the amount to be transfered is in cents, not dollars due to 1:100 scaling
        additionalOwedAmount = CollateralWallet(collateralWallet).collateralMToM(address(this), 
            contractValueChange);
        if (CollateralWallet(collateralWallet).forwardToShortBalance(address(this))
            < newMarginRequirement) 
        {
            if (marginCallIssuedToShort) {
                defaultContract(short, additionalOwedAmount);
            } else {
                shortAmountOwed = (newMarginRequirement - 
                    CollateralWallet(collateralWallet).forwardToShortBalance(
                        address(this))) + additionalOwedAmount;
                marginCallIssuedToShort = true;
            }
        } else {
            marginCallIssuedToShort = false;
        }

        if (CollateralWallet(collateralWallet).forwardToLongBalance(address(this))
            < newMarginRequirement) 
        {
            if (marginCallIssuedToLong) {
                if (!marginCallIssuedToShort) {
                    defaultContract(long, additionalOwedAmount);
                }
            } else {
                longAmountOwed = (newMarginRequirement - 
                    CollateralWallet(collateralWallet).forwardToLongBalance(
                        address(this))) + additionalOwedAmount;
                marginCallIssuedToLong = true;
            }
        } else {
            marginCallIssuedToLong = false;
        }
        prevDayClosingPrice = currentForwardPrice;
        emit MarkedToMarket(contractValueChange, shortAmountOwed, longAmountOwed);
    }

    /// @notice Settle and close contract at expiry.
    function settleAtExpiration() external override {
        require(contractState == ContractState.Initiated, "wrong state");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        uint256 initialContractValue = initialForwardPrice * sizeOfContract;
        uint256 finalContractValue = prevDayClosingPrice * sizeOfContract;
        int profitAndLoss = int256(finalContractValue) - int256(initialContractValue);
        //withdraw link from oracles
        LinkPoolUintOracle(underlyingOracleAddress).withdrawLink();
        LinkPoolValuationOracle(valuationOracleAddress).withdrawLink();
        USDRFROracle(valuationOracleAddress).withdrawLink();
        contractState = ContractState.Settled;
        emit SettledAtExpiration(profitAndLoss);
    }

    /// @notice Defaults contract and transfers all collateral of defaulting party to toher party.
    /// @param _defaultingParty Address of the defaulting party
    /// @param amountStillOwed Amount of collateral still owed by lsoing party after defaulting.
    function defaultContract(address _defaultingParty, uint256 amountStillOwed) public override {
        require(((_defaultingParty == short) || (_defaultingParty == long)), "party err");
        require(contractState == ContractState.Initiated, "state err");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        if (_defaultingParty == short) {
            uint256 shortBalance = CollateralWallet(collateralWallet).forwardToShortBalance(address(this));
            if (shortBalance > 0) {
                CollateralWallet(collateralWallet).transferBalance(address(this), true, shortBalance);
            }
        } else {
            uint256 longBalance = CollateralWallet(collateralWallet).forwardToLongBalance(address(this));
            if (longBalance > 0) {
                CollateralWallet(collateralWallet).transferBalance(address(this), false, longBalance);
            }
        }
        //withdraw link from oracles
        LinkPoolUintOracle(underlyingOracleAddress).withdrawLink();
        LinkPoolValuationOracle(valuationOracleAddress).withdrawLink();
        USDRFROracle(valuationOracleAddress).withdrawLink();
        contractState = ContractState.Defaulted;
        emit Defaulted(_defaultingParty, amountStillOwed);
    }

    /// @notice Withdraw link from forward contract callable by ForwardFactory contract
    function withdrawLinkFromContract() external override onlyOwner{
        require((contractState == ContractState.Settled) || 
                (contractState == ContractState.Defaulted), "state err");
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        uint256 linkBalance = link.balanceOf(address(this));
        require(link.transfer(msg.sender, linkBalance), "Withdraw err.");
        emit LinkWithdrawn(linkBalance);
    }

    /* Getter functions */
    /// @notice Returns current contract state.
    /// @return Current contract state.
    function getContractState() external override view returns(string memory) {
            if (contractState == ContractState.Created) {
                return "Created";
            } else if (contractState == ContractState.Initiated) {
                return "Initiated";
            } else if (contractState == ContractState.Settled) {
                return "Settled";
            } else if (contractState == ContractState.Defaulted) {
                return "Defaulted";
            } else {
                return "state error";
            }
    }

    /// @notice get long party
    /// @return address of long party
    function getLong() external override view returns (address) {
            return long;
    }

    /// @notice get short party
    /// @return address of long party
    function getShort() external view returns (address) {
            return short;
    }

    /// @notice get personal wallet of long party
    /// @return address of long party personal wallet
    function getLongPersonalWallet() external view returns (address) {
        return longPersonalWallet;
    }

    /// @notice get personal wallet of short party
    /// @return address of short party personal wallet
    function getShortPersonalWallet() external view returns (address) {
        return shortPersonalWallet;
    }

}
