pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../extension/Miner.sol";
import "../extension/Adminable.sol";
import "../ching/ChingLogic.sol";
import "../token/ChingToken.sol";

// User can claim the eth reward
// Owner can deposit eth reward
contract Reward is Destructible, Adminable {
    using SafeMath for uint256;

    ChingToken token;
    ChingLogic logic;

    uint256 weiPerToken;
    uint256 totalFund;

    event Claim(address claimer, uint256 amount);
    event Fund(address from, uint256 total, uint256 amount);
  
    function Reward (address _logicAddress, address _tokenAddress, uint256 _weiPerToken) {
      logic = ChingLogic(_logicAddress);    
      token = ChingToken(_tokenAddress); // token
      weiPerToken = _weiPerToken; // How many wei to reward per token
    }  

    // Fallback function
    function () payable {
      fund();
    }

    function fund () payable {
      totalFund += msg.value;
      Fund(msg.sender, totalFund, msg.value);
    }

    function getTotalFund() public view returns (uint256) {
      return totalFund;
    }
    function setWeiPerToken(uint256 _weiPerToken) onlyAdmin {
      weiPerToken = _weiPerToken;
    }
    function getWeiPerToken() public view returns (uint256) {
      return weiPerToken;
    }
    
    // 1) token.approve(address this, uint256 tokenAmount) 
    // 2) claim(tokenAmount)
    function claim (uint256 tokenAmount) {
      token.transferFrom(msg.sender, this, tokenAmount);
      uint256 etherValue = tokenAmount*weiPerToken;
      
      // msg.sender.transfer(value);
      // deposit to ChingLogic contract instead of transfer directly to the wallet.
      totalFund -= etherValue;
      logic.depositEtherFor.value(etherValue)(msg.sender);

      Claim(msg.sender, tokenAmount);
    }

}