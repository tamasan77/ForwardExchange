var PersonalWalletFactory = artifacts.require("./personal-wallet/PersonalWalletFactory.sol");
var PersonalWallet = artifacts.require("./personal-wallet/PersonalWallet.sol");
var TestERC20Token = artifacts.require("./tokens/TestERC20Token.sol");
var CollateralWallet = artifacts.require("./collateral-wallet/CollateralWallet.sol");
var CollateralWalletFactory = artifacts.require("./collateral-wallet/CollateralWalletFactory.sol");

module.exports = async function(deployer, accounts) {
    await deployer.deploy(PersonalWalletFactory);
    await deployer.deploy(PersonalWallet, "Test Wallet", "0x5ab8c40ad1ab62c99611b416c029ad35ac2742e1");
    await deployer.deploy(TestERC20Token, 100000000); //initial supply of a hundered million
    await deployer.deploy(CollateralWallet, "Test Collateral Wallet");
    await deployer.deploy(CollateralWalletFactory);
};
