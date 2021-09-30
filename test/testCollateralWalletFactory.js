const { assert } = require("chai");
const IterableToArrayLike = require("es-abstract/2016/IterableToArrayLike");
const { Contract } = require("web3-eth-contract");

const CollateralWalletFactory = artifacts.require("./collateral-wallet/CollateralWalletFactory.sol");
const CollateralWallet = artifacts.require("./collateral-wallet/CollateralWallet.sol");

contract("CollateralWalletFactory", async accounts => {
    let factoryInstance;
    before(async() => {
        factoryInstance = await CollateralWalletFactory.deployed();
    });
    it("should create Collateral Wallets and store their addresses", async () => {
        await factoryInstance.createCollateralWallet("Test Wallet Zero");
        const testWalletZero = await factoryInstance.collateralWallets(0);
        await factoryInstance.createCollateralWallet("Test Wallet One");
        const testWalletOne = await factoryInstance.collateralWallets(1);
        await factoryInstance.createCollateralWallet("Test Wallet Two");
        const testWalletTwo = await factoryInstance.collateralWallets(2);
        const walletInstanceZero = await CollateralWallet.at(testWalletZero);
        const walletInstanceOne = await CollateralWallet.at(testWalletOne);
        const walletInstanceTwo = await CollateralWallet.at(testWalletTwo);
        assert.equal(await walletInstanceZero.walletName(), "Test Wallet Zero", "wallet deploy error");
        assert.equal(await walletInstanceOne.walletName(), "Test Wallet One", "wallet deploy error");
        assert.equal(await walletInstanceTwo.walletName(), "Test Wallet Two", "wallet deploy error");
    });
})