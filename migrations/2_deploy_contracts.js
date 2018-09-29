var SunVibeToken = artifacts.require("./SunVibeToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(SunVibeToken);
};
