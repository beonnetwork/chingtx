var Miner = artifacts.require("./extension/Miner.sol");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(Miner, {from: accounts[0]});
  let miner = await Miner.deployed();
};
