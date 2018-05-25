var ChingLogic = artifacts.require("./ching/ChingLogic.sol");

module.exports = async function(deployer, network, accounts) {

  // var gas = deployer.deploy(ChingLogic, {from: accounts[0]}).estimateGas(1);
  // console.log('gas', gas);
  await deployer.deploy(ChingLogic, {from: accounts[0]});
  let logic = await ChingLogic.deployed();
  // for(var account of accounts){
  //   await logic.assignMiner(account);
  // }
  // let result = await logic.newAccount("rMvsiCaDKmBKyefuGdDKfkwkxszGgJU9CQ", {from: accounts[0]});
  // console.log(result);
};
