var PersonalWalletFactory = artifacts.require("./personal-wallet/PersonalWalletFactory.sol");

module.exports = async function(deployer) {
    await deployer.deploy(PersonalWalletFactory);
};
