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

    event SettledAtExpiration(int256 profitAndLoss);
    event Defaulted(address defaultingParty);

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
        address _collateralWallet,
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
        require(_CollateralWallet != address(0), "0 address");
        require(_maintenanceMarginRate != 0, "zero maintenance");
        
        long = _long;
        short = _short;
        expirationDate = _expirationDate;
        collateralWallet = _collateralWallet;
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
        LinkPoolValuationOracle(valuationOracleAddress).requestIndexPrice(
            StringManipLibrary.concatenateStringsForURL(
                StringManipLibrary.uint2str(underlyingPrice), 
                StringManipLibrary.int2str(annualRiskFreeRate), 
                StringManipLibrary.uint2str(block.timestamp), 
                StringManipLibrary.uint2str(expirationDate)));
        timeForwardPriceRequested = block.timestamp;
    }

    /// @notice Mark to market function that is called periodically to transfer gains/losses
    /// 
    function markToMarket() external {
        require(contractState == ContractState.Initiated, 
                "Contract not initiated");
        require(DateTimeLibrary.diffSeconds(block.timestamp, expirationDate) > 0);
        require(DateTimeLibrary.diffSeconds(timeForwardPriceRequested, block.timestamp) > 300, "mtom early err");
        uint256 currentForwardPrice = LinkPoolValuationOracle(valuationOracleAddress).unsignedResult();
        uint256 newContractValue = currentForwardPrice * sizeOfContract;
        uint256 oldContractValue = prevDayClosingPrice * sizeOfContract;
        int256 contractValueChange = int256(newContractValue) - int256(oldContractValue);
        uint256 newMarginRequirement = newContractValue * (maintenanceMarginRate / )
        //In this case the amount to be transfered is in cents, not dollars due to 1:100 scaling
        if (contractValueChange > 0) {
            transferCollateralFrom(shortWallet, longWallet, 
                                   uint256(contractValueChange), collateralTokenAddress);
        }
        if (contractValueChange < 0) {
            transferCollateralFrom(longWallet, shortWallet, 
                                   uint256(-contractValueChange), 
                                   collateralTokenAddress);
        }

        prevDayClosingPrice = currentForwardPrice;
        
        //emit MarkedToMarket(block.timestamp, contractValueChange, long, short);
    }
    /*
    /// @notice Transfers collateral from one collateral wallet to the other collateral wallet.
    /// @param senderAddress Address of the wallet from which collateral is transfered.
    /// @param recipientWalletAddress Address of the wallet to which collateral is tranfered.
    /// @param amount Amount of collateral to be transfered.
    /// @param _collateralTokenAddress Address of the collateral token to transfer.
    function transferCollateralFrom(address senderAddress, 
            address recipientWalletAddress, uint256 amount, 
            address _collateralTokenAddress) public returns (bool transfered_)
    {
            CollateralWallet senderWallet = CollateralWallet(senderWalletAddress);
            CollateralWallet recipientWallet = CollateralWallet(recipientWalletAddress);
            uint256 originalSenderMappedBalance = senderWallet.getMappedBalance(
                                                                address(this), 
                                                                _collateralTokenAddress);
            require(originalSenderMappedBalance >= amount, 
                    "balance insufficient");

            //approval might need fixing
            senderWallet.approveSpender(_collateralTokenAddress, 
                                        address(this), amount);
            IERC20(_collateralTokenAddress).transferFrom(senderWalletAddress, 
                                                         recipientWalletAddress, 
                                                         amount);

            //deduct from sender balance mapping
            unchecked {
                uint256 newSenderMappedBalance = originalSenderMappedBalance - amount;
                senderWallet.setNewBalance(address(this), _collateralTokenAddress, 
                                           newSenderMappedBalance);
            }

            //add to recipient balance mapping
            uint256 newRecipientMappedBalance = recipientWallet.getMappedBalance(
                                                                    address(this), 
                                                                    _collateralTokenAddress) 
                                                                    + amount;
            recipientWallet.setNewBalance(address(this), _collateralTokenAddress, 
                                          newRecipientMappedBalance);
 
            transfered_ = true;
    }*/

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

}
