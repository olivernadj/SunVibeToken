var HDWalletProvider = require("truffle-hdwallet-provider");
var infura_apikey = "a66757fc34c8411bb5418876d63569ec";
var mnemonic = "choice throw garlic remember ice mention prefer because roast mad sword burst";


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"  + infura_apikey)
      },
      gas: "4000000",           // 4M
      gasPrice: "20000000000",   // 20gwei
      network_id: 3
    }
  },
  rpc: {
    host: 'localhost',
    post:8080
  }
};
