const CALLGToken = artifacts.require("./CALLGToken.sol");
const CALLToken = artifacts.require("./CALLToken.sol");
const CapitalTechCrowdsale = artifacts.require("./CapitalTechCrowdsale.sol");
module.exports = function(deployer, network, accounts) {
  const wallet = accounts[0];
  return deployer
    .then(() => {
      return deployer.deploy(CALLGToken);
    })
    .then(() => {
      return deployer.deploy(CALLToken);
    })
    .then(() => {
      return deployer.deploy(CapitalTechCrowdsale, wallet, "0x8055d0504666e2B6942BeB8D6014c964658Ca591", CALLToken.address, CALLGToken.address);
    })
    .catch(console.error);
};
