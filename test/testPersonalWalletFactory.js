const { assert } = require("chai");

const PersonalWalletFactory = artifacts.require("./personal-wallet/PersonalWalletFactory.sol");
const PersonalWallet = artifacts.require("./personal-wallet/PersonalWallet.sol");

contract("PersonalWalletFactory", async accounts => {
    let factoryInstance;
    before(async() => {
        factoryInstance = await PersonalWalletFactory.deployed();
    });
    it("should create PersonalWallets and store address", async () => {
        await factoryInstance.createPersonalWallet(accounts[0], "test wallet zero");
        const testWalletAddressZero = await factoryInstance.personalWallets(0);
        await factoryInstance.createPersonalWallet(accounts[1], "test wallet one");
        const testWalletAddressOne = await factoryInstance.personalWallets(1);
        const walletInstanceZero = await PersonalWallet.at(testWalletAddressZero);
        assert.equal(await walletInstanceZero.name(), "test wallet zero", "incorrect name");
        assert.equal(await walletInstanceZero.owner(), accounts[0], "incorrect address");
        const walletInstanceOne = await PersonalWallet.at(testWalletAddressOne);
        assert.equal(await walletInstanceOne.name(), "test wallet one", "incorrect name");
        assert.equal(await walletInstanceOne.owner(), accounts[1], "incorrect address");
    });
    it("should catch empty name error", async () => {
        try {
            await factoryInstance.createPersonalWallet(accounts[0], "");
        } catch(e) {
            assert(e.message.includes("name empty"));
            return;
        }
        assert(false, "empty name error");
    });
})