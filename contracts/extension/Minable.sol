pragma solidity ^0.4.18;

import "./Miner.sol";

contract Minable is Adminable{

  Miner miner;

  modifier onlyMiner() {
    miner.isMiner(msg.sender);
    _;
  }
  
  function setMiner(address _miner) public onlyAdmin {
      miner = Miner(_miner);
  }
  function getMiner() public view returns(address) {
      return address(miner);
  }

}