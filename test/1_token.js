var ChingToken = artifacts.require("./token/ChingToken.sol");
var ChingLogic = artifacts.require("./ching/ChingLogic.sol");
var Hashtag = artifacts.require("./tasks/Hashtag.sol");
var Reward = artifacts.require("./tasks/Reward.sol");

contract('ChingToken', function(accounts) {
  it("should test token", async function() {
    let token = await ChingToken.deployed();

    supply = await token.totalSupply()
    assert.equal(supply.valueOf(), 8.888888e+24, "supply is not equal");
    
    var result;
    result = await token.getTokensPerEther()
    console.log(result);

    result = await token.getLogo()
    console.log(result);
    result = await token.getDescription()
    console.log(result);

    result = await token.setLogo("http://www.google.com")
    let gas = await token.setDescription.estimateGas(`
    Token for the world
    `)
    console.log('gas', gas);
    result = await token.setDescription(`
    Token for the world
    `);

    result = await token.getLogo()
    console.log(result);
    result = await token.getDescription()
    console.log(result);
  });
});
