var ChingToken = artifacts.require("./token/ChingToken.sol");

module.exports = async function(deployer, network, accounts) {

  // ChingToken.web3.eth.getGasPrice(function(error, result){ 
  //   var gasPrice = Number(result);
  //   console.log("Gas Price is " + gasPrice + " wei"); // "10000000000000"

  //   // Get Contract instance
  //   ChingToken.deployed().then(function(instance) {

  //       // Use the keyword 'estimateGas' after the function name to get the gas estimation for this particular function 
  //       return instance.giveAwayDividend.estimateGas(1);

  //   }).then(function(result) {
  //       var gas = Number(result);

  //       console.log("gas estimation = " + gas + " units");
  //       console.log("gas cost estimation = " + (gas * gasPrice) + " wei");
  //       console.log("gas cost estimation = " + TestContract.web3.fromWei((gas * gasPrice), 'ether') + " ether");
  //   });
  // });

  let decimals = 18
  let supply = 88888888
  await deployer.deploy(ChingToken, 8888888, "Ching", decimals, "CHG", 1, supply, {from: accounts[0]})
  let token = await ChingToken.deployed();
};
