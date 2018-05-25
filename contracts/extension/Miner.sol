pragma solidity ^0.4.18;

import "./Adminable.sol";

contract Miner is Adminable{

  mapping (address => bool) miners;

  function isMiner(address target) public view returns (bool) {
      return miners[target];
  }
  function assignMiner(address target) onlyAdmin public {
      miners[target] = true;
  }
  function revokeMiner(address target) onlyAdmin public {
      miners[target] = false;
  }   

}

