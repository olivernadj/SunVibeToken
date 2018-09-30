var SafeMath = artifacts.require("./SafeMath.sol");
var SunVibeToken = artifacts.require("./SunVibeToken.sol");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, SunVibeToken);
  deployer.deploy(SunVibeToken, { from: accounts[0] });
};
