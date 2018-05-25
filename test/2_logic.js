var ChingToken = artifacts.require("./token/ChingToken.sol");
var ChingLogic = artifacts.require("./ching/ChingLogic.sol");
var Hashtag = artifacts.require("./tasks/Hashtag.sol");
var Reward = artifacts.require("./tasks/Reward.sol");
var Miner = artifacts.require("./extension/Miner.sol");
var Web3 = require('web3');
var web3 = new Web3(
  new Web3.providers.WebsocketProvider('ws://localhost:7545/')
);

async function ecSign(txhash, account){
  let sig = await web3.eth.sign(txhash, account);
  sig = sig.slice(2, sig.length);
  let r = '0x' + sig.slice(0, 64);
  let s = '0x' + sig.slice(64, 128);
  let v = web3.utils.toDecimal(sig.slice(128, 130)) + 27;
  return {r:r, s:s, v:v};
}

contract('ChingLogic', function(accounts) {
  it("should test logic", async function() {
    
    var miner = await Miner.deployed();
    for(var account of accounts){
      await miner.assignMiner(account);
    }

    var chingToken = await ChingToken.deployed();
    var chingTokenAddress = chingToken.address;
    var result;
    let logic = await ChingLogic.deployed();
    
    let web3logic = new web3.eth.Contract(require('../build/contracts/ChingLogic.json').abi, logic.address)
    web3logic.events.TokenDeposited()
    .on("data", function(data){
      console.log('[EVENT] TokenDeposited', data.returnValues.tokenAmount);
    })

    // var subscription = web3.eth.subscribe('logs', {
    //   address: logic.address,
    //   topics: [null]
    // }, function(error, result){
    //   console.log('subscription result', result);
    // })
    // .on("data", function(log){
    //   console.log('subscription result data',log);
    // })
    // .on("changed", function(log){
    //   console.log('subscription result changed',log);
    // });
    
    logic.setMiner(miner.address);
    
    result = await logic.newAccount("rMvsiCaDKmBKyefuGdDKfkwkxszGgJU9CQ", {
      from: accounts[0]
    });
    result = await logic.getApprovalThreshold();
    result = await logic.setApprovalThreshold(2);
    
    let decimals = 18
    let multiplier = Math.pow(10,decimals)
    let supply = 88888888 * multiplier    
    var token = await ChingToken.new(1000, "Ching", decimals, "Ching", 1, supply, {from: accounts[0]});
    // console.log("token", token.address);
    var reward = await Reward.new(logic.address, token.address, 1);
    // console.log("reward", reward.address);
    result = await logic.newToken(token.address, reward.address);
    // console.log("result", result);
    result = await logic.getNumTokensOf(accounts[0]);
    console.log('getNumTokensOf', result.valueOf());
    var tokenAddress = await logic.getTokenOfAt(accounts[0], 0);
    var rewardAddress = await logic.getRewardOf(tokenAddress);
    assert(token.address == tokenAddress, 'token address not correct');
    assert(reward.address == rewardAddress, 'reward address not correct');
    // console.log(tokenAddress, rewardAddress);

    var hashtag = await Hashtag.new(logic.address, token.address, "chingwallet", {from: accounts[0]});    
    hashtag.setMiner(miner.address);

    result = await logic.newHashTagTask(tokenAddress, hashtag.address);
    
    result = await logic.getNumTasksOf(tokenAddress);
    // console.log('result', result);
    result = await logic.getTaskOfAt(tokenAddress, 0);
    // console.log('result', result);

    result = await logic.newAccountFor(accounts[1], "aMvsiCaDKmBKyefuGdDKfkwkxszGgJU9CQ");
    
    result = await logic.accountOf(accounts[0]);
    console.log('accountOf', 0, result);
    result = await logic.accountOf(accounts[1]);
    console.log('accountOf', 1, result);

    result = await token.approve(logic.address, 200);
    console.log('approve', result.logs[0].args);
    result = await token.allowance(accounts[0], logic.address);
    console.log('allowance', result);
    result = await token.balanceOf(accounts[0]);
    console.log('balanceOf', 0, result.valueOf());
    result = await token.balanceOf(accounts[1]);
    console.log('balanceOf', 1, result.valueOf());
    // console.log(token,logic,result);
    result = await logic.depositToken(token.address, 100, {from: accounts[0]});
    result = await logic.depositTokenFor(token.address, accounts[1], 100, {from: accounts[0]});

    result = await logic.depositEther({from: accounts[0], value: 10});
    result = await logic.depositEtherFor(accounts[1], {from: accounts[0], value: 10});

    result = await logic.tokenBalanceOf(token.address, accounts[0]);
    console.log('tokenBalanceOf', 0, result);
    result = await logic.tokenBalanceOf(token.address, accounts[1]);
    console.log('tokenBalanceOf', 1, result);
    result = await logic.etherBalanceOf(accounts[0]);
    console.log('etherBalanceOf', 0, result);
    result = await logic.etherBalanceOf(accounts[1]);
    console.log('etherBalanceOf', 1, result);
    // result = await logic.tokenBalanceOf(token.address, accounts[0]);
    // console.log('AT tokenBalanceOf', 0, result);
    // result = await logic.tokenBalanceOf(token.address, accounts[1]);
    // console.log('AT tokenBalanceOf', 1, result);
    var seq = 1;
    var tamount = 10;
    var txId = seq;

    var txhash = web3.utils.soliditySha3(token.address, seq, accounts[0], accounts[1], tamount);
    
    let sig = await web3.eth.sign(txhash, accounts[0]);
    sig = sig.slice(2, sig.length);
    let r = '0x' + sig.slice(0, 64);
    let s = '0x' + sig.slice(64, 128);
    let v = web3.utils.toDecimal(sig.slice(128, 130)) + 27;
    
    result = await logic.approveWithdrawalOfToken(token.address, txId, seq, accounts[0], accounts[1], tamount, v, r, s, {from: accounts[3]});
    result = await logic.approveWithdrawalOfToken(token.address, txId, seq, accounts[0], accounts[1], tamount, v, r, s, {from: accounts[4]});
    // console.log('result', result.logs[0].args);

    for (let i = 0; i < accounts.length; i++) {
      result = await token.balanceOf(accounts[i]);
      console.log('balanceOf', i, result.valueOf());        
      result = await logic.tokenBalanceOf(token.address, accounts[i]);
      console.log('tokenBalanceOf', i, result.valueOf());
    }
    
    for (let i = 0; i < accounts.length; i++) {
      result = await token.balanceOf(accounts[i]);
      console.log('balanceOf', i, result.valueOf());        
      result = await logic.tokenBalanceOf(token.address, accounts[i]);
      console.log('tokenBalanceOf', i, result.valueOf());
    }

    txhash = web3.utils.soliditySha3(seq, accounts[0], accounts[1], tamount);
    let obj = await ecSign(txhash, accounts[0]);
    r = obj.r;
    s = obj.s;
    v = obj.v;
    
    result = await logic.approveWithdrawalOfEther(txId, seq, accounts[0], accounts[1], tamount, v, r, s, {from: accounts[3]});
    result = await logic.approveWithdrawalOfEther(txId, seq, accounts[0], accounts[1], tamount, v, r, s, {from: accounts[4]});
    // console.log('result', result.logs[0].args);

    for (let i = 0; i < accounts.length; i++) {
      result = await web3.eth.getBalance(accounts[i]);
      console.log('ETH balanceOf', i, result.valueOf());        
      result = await logic.etherBalanceOf(accounts[i]);
      console.log('ETH balanceOf', i, result.valueOf());
    }

    result = await hashtag.setApprovalThreshold(1);
    result = await hashtag.getApprovalThreshold();
    console.log('getApprovalThreshold', result.valueOf());
    result = await hashtag.setTokensPerTweet(1);
    result = await hashtag.getTokensPerTweet();
    console.log('getTokensPerTweet', result.valueOf());

    // result = await hashtag.fund(100, {from: accounts[0]});
    // console.log('result',result);
    // assert(false, 'nothing');
    // console.log('fund', result);
    result = await token.mint(hashtag.address, 100);
    result = await token.balanceOf(hashtag.address);
    console.log('hashtag fund', result.valueOf());        


    txId = "1";
    let timestamp = Date.now();
    let tag = "chingwallet";
    let handle = "steerapi";

    result = await hashtag.signup(handle, accounts[0]);
    // console.log(result);

    result = await hashtag.approveReward(txId, timestamp, tag, handle, {from: accounts[3]});
    // console.log(result);

    result = await token.balanceOf(accounts[0]);
    console.log('balanceOf', 0, result.valueOf());
    result = await logic.tokenBalanceOf(token.address, accounts[0]);
    console.log('tokenBalanceOf', 0, result.valueOf());
    
    result = await reward.fund({from: accounts[0], value: 1e12});
    result = await reward.getTotalFund();
    result = await reward.setWeiPerToken(1);
    result = await reward.getWeiPerToken();
    result = await token.approve(reward.address, 1); 
    result = await reward.claim(1);
    // console.log(result.logs);

    result = await logic.etherBalanceOf(accounts[0]);    
    console.log('etherBalanceOf', 0, result.valueOf());

    // result = await hashtag.reward(10);
    // console.log('result', result.logs[1].args);
    // console.log('result', result.logs[2].args);
    // console.log('v', result);
    // console.log('result', result.logs[0].args);
    // // result = await logic.approveWithdrawalOfEther(chingTokenAddress, {from: accounts[0], value: 10});
  });
});
