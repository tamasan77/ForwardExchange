const { assert } = require("chai");

const PersonalWallet = artifacts.require("./personal-wallet/PersonalWallet.sol");
const TestERC20Token = artifacts.require("./tokens/TestERC20Token.sol");
const CollateralWallet = artifacts.require("./collateral-wallet/CollateralWallet.sol");

contract("PersonalWallet", async accounts => {
    let walletInstance;
    let erc20TokenInstance;
    let collateralWalletInstance;
    let testERC20TokenAddress;
    let mainnetLinkAddress;
    let kovanLinkAddress;
    before(async() => {
        walletInstance = await PersonalWallet.deployed();
        erc20TokenInstance = await TestERC20Token.deployed();
        collateralWalletInstance = await CollateralWallet.deployed();
        testERC20TokenAddress = web3.utils.toChecksumAddress(erc20TokenInstance.address);
        mainnetLinkAddress = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
        kovanLinkAddress = "0xa36085F69e2889c224210F603D836748e7dC0088";
    });
    it("should deploy Personal Wallet properly", async () => {
        assert(walletInstance.address != "", "deployment failed");
    });
    it("should add new token to the token array", async () => {
        await walletInstance.addNewToken(testERC20TokenAddress);
        await walletInstance.addNewToken(mainnetLinkAddress);
        await walletInstance.addNewToken(kovanLinkAddress);
        assert.equal(await walletInstance.tokens(0), testERC20TokenAddress, 
            "token address not added");
        assert.equal(await walletInstance.tokens(1), mainnetLinkAddress, 
            "token address not added");
        assert.equal(await walletInstance.tokens(2), kovanLinkAddress, 
            "token address not added");
    });
    it("should not add existing token to the token array again", async () => {
        await walletInstance.addNewToken(testERC20TokenAddress);
        try {
            await walletInstance.tokens(3);//this should revert
        } catch(e) {
            return;
        }
        assert(false, "existing token error");
    });
    it("should approve collateral wallet to transfer collateral", async () => {
        assert.equal(await collateralWalletInstance.walletName(), 
            "Test Collateral Wallet", 
            "collateral wallet not deployed correctly");
        const collateralWalletAddress = collateralWalletInstance.address;
        //transfer 20MIL collateral tokens to personal wallet
        await erc20TokenInstance.transfer(walletInstance.address, 20000000);
        await walletInstance.approveCollateral(
            collateralWalletAddress, 
            testERC20TokenAddress, 
            8000000);
        assert.equal(await erc20TokenInstance.allowance(walletInstance.address, collateralWalletAddress), 
            8000000, 
            "allowance error");
    });
    it("should catch a non-existing token's approval error", async () => {
        //rinkeby link has not been added to the wallet
        const rinkebyLinkAddress = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709";
        const collateralWalletAddress = collateralWalletInstance.address;
        try {
            await walletInstance.approveCollateral(collateralWalletAddress, 
                rinkebyLinkAddress, 
                8000000);
        } catch(e) {
            assert(e.message.includes("coll token err"));
            return;
        }
        assert(false, "non-existing token error");
    });
    it("should catch an approval amount greater than balance error", async () => {
        const collateralWalletAddress = collateralWalletInstance.address;
        try {
            await walletInstance.approveCollateral(collateralWalletAddress, 
                testERC20TokenAddress, 
                21000000);//21MIL greater than balance of 20MIL
        } catch(e) {
            assert(e.message.includes("balance err"));
            console.log(e.message);
            return;
        }
        assert(false, "greater than balance error");
    });
});