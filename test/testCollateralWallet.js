const { assert } = require("chai");
const IterableToArrayLike = require("es-abstract/2016/IterableToArrayLike");

const CollateralWallet = artifacts.require("./collateral-wallet/CollateralWallet.sol");
const PersonalWalletFactory = artifacts.require("./personal-wallet/PersonalWalletFactory.sol");
const PersonalWallet = artifacts.require("./personal-wallet/PersonalWallet.sol");
const ForwardContractMock = artifacts.require("./mocks/ForwardContractMock.sol");
const TestERC20Token = artifacts.require("./tokens/TestERC20Token.sol");

contract("CollateralWallet", async accounts => {
    let walletInstance;
    let personalWalletFactoryInstance;
    let shortPersonalWalletInstance;
    let longPersonalWalletInstance;
    let forwardContractInstance;
    let erc20TokenInstance;
    let forwardContractAddress;
    before(async() => {
        walletInstance = await CollateralWallet.deployed();
        personalWalletFactoryInstance = await PersonalWalletFactory.deployed();
        forwardContractInstance = await ForwardContractMock.deployed();
        forwardContractAddress = forwardContractInstance.address;
        erc20TokenInstance = await TestERC20Token.deployed();
        await personalWalletFactoryInstance.createPersonalWallet(accounts[0], "Short Personal Wallet");
        await personalWalletFactoryInstance.createPersonalWallet(accounts[1], "Long Personal Wallet");
        const shortPersonalWalletAddress=  await personalWalletInstance.personalWallets(0);
        const longPersonalWalletAddress = await personalWalletInstance.personalWallets(1);
        shortPersonalWalletInstance = await PersonalWallet.at(shortPersonalWalletAddress);
        longPersonalWalletInstance = await PersonalWallet.at(longPersonalWalletAddress);
        await forwardContractInstance.setPersonalWallets(shortPersonalWalletAddress, longPersonalWalletAddress);
        testERC20TokenAddress = web3.utils.toChecksumAddress(erc20TokenInstance.address);
        await shortPersonalWalletInstance.addNewToken(testERC20TokenAddress);
        await longPersonalWalletInstance.addNewToken(testERC20TokenAddress);
        //have 20MIL test ERC20 tokens in both wallets to start with
        await erc20TokenInstance.transfer(shortPersonalWalletInstance.address, 20000000);
        await erc20TokenInstance.transfer(longPersonalWalletInstance.address, 20000000);
    });
    it("should deploy properly", async () => {
        assert.equal(await walletInstance.walletName(), "Test Collateral Wallet", "deployment error");
    });
    it("should transfer initial collateral from both personal wallets, store forward contract address and store collateral token address if not stored yet", 
        async () => {
        const initialCollateralAmount = 4000000;//4MIL
        //aprove the amount from personal wallets
        await shortPersonalWalletInstance.approveCollateral(
            walletInstance.address, 
            testERC20TokenAddress, 
            4000000);
        await longPersonalWalletInstance.approveCollateral(
            walletInstance.address, 
            testERC20TokenAddress, 
            4000000);
        await walletInstance.setupInitialCollateral(
            forwardContractAddress,
            shortPersonalWalletAddress,
            longPersonalWalletAddress,
            testERC20TokenAddress,
            initialCollateralAmount
        );
        assert.equal(await walletInstance.tokens(0), testERC20TokenAddress, "token not added");
        assert.equal(await walletInstance.forwardContract(0), forwardContractAddress, "forward contract not added");
        assert.equal(await walletInstance.forwardToShortWallet(forwardContractAddress), shortPersonalWalletAddress, "short wallet not set");
        assert.equal(await walletInstance.forwardToLongWallet(forwardContractAddress), longPersonalWalletAddress, "long wallet not set");
        assert.equal(await walletInstance.forwardToShortBalance(forwardContractAddress), initialCollateralAmount, "short balance not set");
        assert.equal(await walletInstance.forwardToLongBalance(forwardContractAddress), initialCollateralAmount, "long balance not set");
        assert.equal(await erc20TokenInstance.balanceOf(walletInstance.address), 2 * initialCollateralAmount, "collateral wallet balance incorrect");
        assert.equal(await erc20TokenInstance.balanceOf(shortPersonalWalletAddress), 16000000, "short personal wallet balance incorrect");
        assert.equal(await erc20TokenInstance.balanceOf(longPersonalWalletAddress), 16000000, "long personal wallet balance incorrect");
    });
    it("should adjust balances of two parties according to m-to-m", async () => {

    });
    it("should return collateral long and short parties", async () => {

    });
    it("should transfer balance of two parties internally", async () => {

    });
    it("should transfer collateral from given personal wallet corresponding to a forward contract", async () => {

    });
})