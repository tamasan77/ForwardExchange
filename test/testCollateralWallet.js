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
    before(async() => {
        walletInstance = await CollateralWallet.deployed();
        personalWalletFactoryInstance = await PersonalWalletFactory.deployed();
        forwardContractInstance = await ForwardContractMock.deployed();
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
    it("should transfer initial collateral from both personal wallets", async () => {
        
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