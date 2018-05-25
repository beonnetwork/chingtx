pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../extension/Minable.sol";
import "../extension/Adminable.sol";
import "../token/ChingToken.sol";
import "../ching/ChingLogic.sol";

contract Hashtag is Destructible, Minable {
    using SafeMath for uint256;

    string tag;

    ChingToken token;
    ChingLogic logic;

    mapping (string => address) handleAddresses;

    uint256 approvalThreshold;

    uint256 tokensPerTweet;

    struct ConfirmData {
      uint256 timestamp;
      string txId;
      string tag;
      string handle;
      bool confirmed;
    }

    struct Confirmation {
      uint256 timestamp;
      string txId;
      string tag;
      string handle;

      address[] approvers;
      bool withdrawn;
      mapping (address => ConfirmData) approvers_mask;
      uint256 count;
    }

    mapping (bytes32 => Confirmation) confirmations;

    event HashtagReward(string handle, address to, uint256 amount);
    event HashtagSignup(string handle, address addr);

    function Hashtag (address _logicAddress, address _tokenAddress, string _tag) {
        logic = ChingLogic(_logicAddress);    
        token = ChingToken(_tokenAddress);
        tag = _tag;
        approvalThreshold = 1;
        tokensPerTweet = 1;
    }
    function getApprovalThreshold() public view returns (uint256) {
        return approvalThreshold;
    }
    function setApprovalThreshold(uint256 value) onlyAdmin {
        approvalThreshold = value;
    }
    function getTokensPerTweet() public view returns (uint256) {
        return tokensPerTweet;
    }
    function setTokensPerTweet(uint256 value) onlyAdmin {
        tokensPerTweet = value;
    }
  
    // sign up for a task
    function signup (string handle, address addr) {
        handleAddresses[handle] = addr;
        HashtagSignup(handle, addr);
    }

    //event Txhash(bytes32 txhash);

    // miner approver the rewards
    function approveReward(string txId, uint256 timestamp, string _tag, string handle) onlyMiner {
      // require(_tag == tag);
      bytes32 txhash = keccak256(txId, timestamp, tag, handle);
      //Txhash(txhash);
      if ( confirmations[txhash].withdrawn != true && confirmations[txhash].approvers_mask[msg.sender].confirmed != true ) {
        confirmations[txhash].approvers.push(msg.sender);

        confirmations[txhash].approvers_mask[msg.sender].confirmed = true;
        confirmations[txhash].approvers_mask[msg.sender].txId = txId;
        confirmations[txhash].approvers_mask[msg.sender].tag = tag;
        confirmations[txhash].approvers_mask[msg.sender].handle = handle;
        confirmations[txhash].approvers_mask[msg.sender].timestamp = timestamp;

        confirmations[txhash].txId = txId;
        confirmations[txhash].tag = tag;
        confirmations[txhash].handle = handle;
        confirmations[txhash].timestamp = timestamp;
        
        confirmations[txhash].count += 1;

        // if it is the first time, emit events to randomly select miner to verify
        // subtract stakes of the miner
        if (confirmations[txhash].count >= approvalThreshold) {
          confirmations[txhash].withdrawn = true;
          reward(handle);
          // return stakes to miners
        }
      }
    }
    
    //function minerStake(uint256 amount){
    //  stakes[msg.sender] = amount;
    //}

    // function fund(uint256 amount) public onlyAdmin {
    //   Fund(amount);
    //   // token.mint(address(this), amount);
    //   // ChingLogic.deposit
    //   // token.approve(address(logic), amount);
    //   // logic.newAccount(this);
    //   // logic.depositTokenFor(address(token), this, amount);
    // }

    // 1) token.mint(address(this), amount);
    // 2) reward
    function reward(string handle) {
      // token.transfer(to, amount);
      // ChingLogic.deposit
      require(handleAddresses[handle] != 0);
      address to = handleAddresses[handle];
      uint256 amount = tokensPerTweet;      
      token.approve(address(logic), amount);
      logic.depositTokenFor(address(token), to, amount);

      HashtagReward(handle, to, amount);
    }
}