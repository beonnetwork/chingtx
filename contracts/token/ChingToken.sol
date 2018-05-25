/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20), the ERC223 functionality (https://github.com/ethereum/EIPs/issues/223) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.

.*/

pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/CappedToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../extension/Adminable.sol";
// import "../utils/strings.sol";

contract ChingToken is Adminable,ERC827Token,BurnableToken,CappedToken,PausableToken {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    // using strings for *;
    
    /*
    NOTE:
    The following variables were optional. Now, they are included in ERC 223 interface.
    They allow one to customise the token contract & in no way influences the core functionality.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    uint256 multiplier;

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public version = "1.0.0-alpha.1";       //human 0.1 standard. Just an arbitrary versioning scheme.
    
    uint256 tokensPerWei;
    
    string public logo;
    string public description;
    string public tagline;

    function ChingToken (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        uint256 _tokensPerWei,
        uint256 _cap
    ) CappedToken(_cap*(10**uint256(_decimalUnits))) public {
        multiplier = 10**(uint256(_decimalUnits));
        balances[owner] = _initialAmount*multiplier;         // Give the creator all initial tokens
        totalSupply_ = _initialAmount*multiplier;            // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        tokensPerWei = _tokensPerWei;
        // string memory json = '{"key":"value"}';
        // keccak256(123);
    }

    function getTokensPerEther() public view returns (uint256) {
        return tokensPerWei;
    }

    function setTokensPerEther(uint256 value) public onlyAdmin {
        tokensPerWei = value;
    }
    
    function getLogo() public view returns (string) {
        return logo;
    }

    function setLogo(string value) public onlyAdmin {
        logo = value;
    }

    function getDescription() public view returns (string) {
        return description;
    }
    
    function setDescription(string value) public onlyAdmin {
        description = value;
    }

    function getTagline() public view returns (string) {
        return tagline;
    }
    
    function setTagline(string value) public onlyAdmin {
        tagline = value;
    }

    function getName() public view returns (string) {
        return name;
    }
    
    function setName(string value) public onlyAdmin {
        name = value;
    }

    function buy()
        public
        payable
    {
        // require(msg.value >= 1 ether);
        uint256 num = msg.value*tokensPerWei;
        totalSupply_ += num;
        balances[msg.sender] = SafeMath.add(balances[msg.sender], num);
        owner.transfer(msg.value);
    }

    // Admin operations
    function setNewCap(uint256 _newcap) onlyAdmin public
    {
        require(_newcap > 0);
        require(_newcap >= totalSupply_);
        cap = _newcap;
    }

    function burnFrom(address _from, uint256 _value) onlyAdmin public {
        require(_value > 0);
        require(_value <= balances[_from]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = _from;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ -= _value;
        Burn(burner, _value);
    }

}
