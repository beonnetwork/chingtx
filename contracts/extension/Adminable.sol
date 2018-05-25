pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Adminable is Ownable{

  mapping (address => bool) delegates;

  modifier onlyAdmin() {
    require(msg.sender == owner || delegates[msg.sender] == true);
    _;
  }

  function isDelegate(address target) constant public returns (bool) {
      return delegates[target];
  }
  function assignDelegate(address target) onlyAdmin public {
      delegates[target] = true;
  }
  function revokeDelegate(address target) onlyAdmin public {
      delegates[target] = false;
  }   
}