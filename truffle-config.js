const path = require("path");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      port: 8545,
      gas: 4600000, 
      network_id: "*"
    },
    ganache_local: {
      port: 7545,
      network_id: 5777,
      host: "127.0.0.1",
      gas: 8000000,
      gasPrice: 20000000000
    }

  },
  compilers: {
    solc: {
      version: "^0.8.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
