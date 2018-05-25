pragma solidity ^0.4.18;

// import "../utils/strings.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "../extension/Minable.sol";
import "../token/ChingToken.sol";
import "../tasks/Hashtag.sol";
import "../tasks/Reward.sol";

contract ChingLogic is Destructible, Minable {
    using SafeMath for uint256;
    // using strings for *;

    mapping (address => uint256) escrow;
    mapping (address => mapping (address => uint256)) tokenEscrow;
    mapping (address => address[]) tokenAddresses;    
    mapping (address => address) tokenRewards;
    mapping (address => address[]) tokenTasks;
    
    mapping (string => bool) rippleAddresses;
    mapping (address => string) accounts;
    mapping (bytes32 => Confirmation) confirmations;
    uint256 approvalThreshold;

    event TokenDeposited(address tokenAddress, address fromAddress, string fromRippleAddress, uint256 tokenAmount);
    event EtherDeposited(address fromAddress, string fromRippleAddress, uint256 amount);
    event TokenWithdrawn(address tokenAddress, address from, address to, uint256 amount);
    event EtherWithdrawn(address from, address to, uint256 amount);
    event AccountCreated(string rippleAddress, address ethAddress);
    event NewTokenIssued(address tokenAddress, address rewardAddress);
    event NewHashtagTaskCreated(address tokenAddress, address hashtagAddress);
    
    // event Approval(address vfrom, address from);    
    // event Txhash(bytes32 txhash, uint8 v, bytes32 r, bytes32 s);
    // event Debug(uint256 value);

    struct ConfirmData {
      string txId;
      uint256 seq;
      address from;
      address to;
      uint256 amount;
      bool confirmed;
    }
    struct Confirmation {
      string txId;
      uint256 seq;
      address from;
      address to;
      uint256 amount;
      address tokenAddress;
      address[] approvers;
      bool withdrawn;
      mapping (address => ConfirmData) approvers_mask;
      uint256 count;
    }

    function ChingLogic () {
        approvalThreshold = 1;
    }

    function getApprovalThreshold() public view returns (uint256) {
        return approvalThreshold;
    }
    function setApprovalThreshold(uint256 value) onlyAdmin {
        approvalThreshold = value;
    }

    function newToken(address _tokenAddress, address _rewardAddress) {
      ChingToken token = ChingToken(_tokenAddress);//new ChingToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol, _tokensPerWei, _cap);
      Reward reward = Reward(_rewardAddress);//new Reward(this, address(token), _weiPerToken);      
      tokenAddresses[msg.sender].push(address(token));
      tokenRewards[address(token)] = address(reward);
      NewTokenIssued(_tokenAddress, _rewardAddress);
    }
    
    function getNumTokensOf(address _owner) public view returns (uint256){
      return tokenAddresses[_owner].length;
    }
    function getTokenOfAt(address _owner, uint256 i) public view returns (address){
      return tokenAddresses[_owner][i];
    }
    function getRewardOf(address token) public view returns (address){
      return tokenRewards[token];
    }

    function newHashTagTask(address _tokenAddress, address _hashtagAddress) {
      Hashtag hashtag = Hashtag(_hashtagAddress);
      // Reward reward = Reward(rewardAddresses[tokenAddress]);
      tokenTasks[_tokenAddress].push(address(hashtag));
      NewHashtagTaskCreated(_tokenAddress, _hashtagAddress);
    }
    function getNumTasksOf(address _token) public view returns (uint256){
      return tokenTasks[_token].length;
    }
    function getTaskOfAt(address _token, uint256 i) public view returns (address){
      return tokenTasks[_token][i];
    }

    function newAccountFor(address _for, string rippleAddress) onlyAdmin {
        require(bytes(accounts[_for]).length == 0);
        require(rippleAddresses[rippleAddress] != true);

        accounts[_for] = rippleAddress;
        rippleAddresses[rippleAddress] = true;
        AccountCreated(rippleAddress, _for);
    }
    function newAccount(string rippleAddress) {
        require(bytes(accounts[msg.sender]).length == 0);
        
        accounts[msg.sender] = rippleAddress;
        AccountCreated(rippleAddress, msg.sender);
    }
    function accountOf(address addr) public view returns (string) {
        return accounts[addr];
    }
    

    function tokenBalanceOf(address tokenAddress, address owner) public view returns (uint256) {
      return tokenEscrow[tokenAddress][owner];
    }
    function etherBalanceOf(address owner) public view returns (uint256) {
      return escrow[owner];
    }

    // 1) token.approve(address this, uint256 tokenAmount) 
    // 2) depositToken(tokenAmount)
    function depositToken(address tokenAddress, uint256 tokenAmount) public {
      ChingToken token = ChingToken(tokenAddress);
      token.transferFrom(msg.sender, address(this), tokenAmount);
      tokenEscrow[tokenAddress][msg.sender] = tokenAmount;
      TokenDeposited(tokenAddress, msg.sender, accounts[msg.sender], tokenAmount);
    }
    // 1) token.approve(address this, uint256 tokenAmount) 
    // 2) depositTokenFor(tokenAddress, for, tokenAmount)
    function depositTokenFor(address tokenAddress, address _for, uint256 tokenAmount) public {
      ChingToken token = ChingToken(tokenAddress);
      token.transferFrom(msg.sender, address(this), tokenAmount);
      tokenEscrow[tokenAddress][_for] = tokenAmount;
      TokenDeposited(tokenAddress, _for, accounts[_for], tokenAmount);
    }
    
    function depositEther() public payable {
      address from = msg.sender;
      uint256 value =  msg.value;      
      escrow[from] += value;
      EtherDeposited(from, accounts[from], value);
    }
    
    function depositEtherFor(address _for) public payable {
      address from = _for;
      uint256 value =  msg.value;
      escrow[from] += value;
      EtherDeposited(from, accounts[from], value);
    }

    // function bytes32ToString (bytes32 data) returns (string) {
    //   bytes memory bytesString = new bytes(32);
    //   for (uint j=0; j < 32; j++) {
    //     byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
    //     if (char != 0) {
    //         bytesString[j] = char;
    //     }
    //   }
    //   return string(bytesString);
    // }

    // function ecrecover2(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) constant returns (address) {
    //   bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    //   bytes32 prefixedHash = keccak256(prefix, msgHash);
    //   return ecrecover(prefixedHash, v, r, s);
    // }

    function approveWithdrawalOfToken(address tokenAddress, string txId, uint256 seq, address from, address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) public onlyMiner {
      // string txdata;// = "{from:from, amount:amount, to:to, currency:ETH, fromRippleAddress:fromRippleAddress, toRippleAddress:toRippleAddress, fromRippleBalance:rippleBalance, toRippleBalance:rippleBalance}";
      // string memory txdata = '{"key":"value"}'.toSlice().concat(''.toSlice());
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";      
      bytes32 txhash = keccak256(tokenAddress, seq, from, to, amount);
      //Txhash(txhash, v, r, s);
      bytes32 prefixedHash = keccak256(prefix, txhash);
      address vfrom = ecrecover(prefixedHash, v, r, s);
      // verify that the address owner approve this
      //Approval(vfrom, from);
      require(vfrom == from);
      if ( confirmations[txhash].withdrawn != true && confirmations[txhash].approvers_mask[msg.sender].confirmed != true ){
        confirmations[txhash].approvers.push(msg.sender);
        confirmations[txhash].approvers_mask[msg.sender].confirmed = true;
        confirmations[txhash].approvers_mask[msg.sender].txId = txId;
        confirmations[txhash].approvers_mask[msg.sender].seq = seq;
        confirmations[txhash].approvers_mask[msg.sender].from = from;
        confirmations[txhash].approvers_mask[msg.sender].to = to;
        confirmations[txhash].approvers_mask[msg.sender].amount = amount;

        confirmations[txhash].txId = txId;
        confirmations[txhash].seq = seq;
        confirmations[txhash].from = from;
        confirmations[txhash].to = to;
        confirmations[txhash].amount = amount;
        confirmations[txhash].tokenAddress = tokenAddress;
        
        // TODO[Phase 2]: Pick random miner
        confirmations[txhash].count += 1;

        if (confirmations[txhash].count >= approvalThreshold) {
          confirmations[txhash].withdrawn = true;
          withdrawToken(tokenAddress, from, to, amount);
        }
      }
    }

    function approveWithdrawalOfEther(string txId, uint256 seq, address from, address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) public onlyMiner {
      // string txdata;// = "{from:from, amount:amount, to:to, currency:ETH, fromRippleAddress:fromRippleAddress, toRippleAddress:toRippleAddress, fromRippleBalance:rippleBalance, toRippleBalance:rippleBalance}";
      // string memory txdata = '{"key":"value"}'.toSlice().concat(''.toSlice());
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";      
      bytes32 txhash = keccak256(seq, from, to, amount);
      bytes32 prefixedHash = keccak256(prefix, txhash);
      address vfrom = ecrecover(prefixedHash, v, r, s);
      // verify that the address owner approve this
      require(vfrom == from);
      if ( confirmations[txhash].withdrawn != true && confirmations[txhash].approvers_mask[msg.sender].confirmed != true ){
        confirmations[txhash].approvers.push(msg.sender);

        confirmations[txhash].approvers_mask[msg.sender].confirmed = true;
        confirmations[txhash].approvers_mask[msg.sender].txId = txId;
        confirmations[txhash].approvers_mask[msg.sender].seq = seq;
        confirmations[txhash].approvers_mask[msg.sender].from = from;
        confirmations[txhash].approvers_mask[msg.sender].to = to;
        confirmations[txhash].approvers_mask[msg.sender].amount = amount;

        confirmations[txhash].txId = txId;
        confirmations[txhash].seq = seq;
        confirmations[txhash].from = from;
        confirmations[txhash].to = to;
        confirmations[txhash].amount = amount;
        
        // TODO[Phase 2]: Pick random miner
        confirmations[txhash].count += 1;
        if (confirmations[txhash].count >= approvalThreshold) {
          confirmations[txhash].withdrawn = true;
          withdrawEther(from, to, amount);
        }
      }
    }

    function withdrawToken(address tokenAddress, address from, address to, uint256 amount) private {
      ChingToken token = ChingToken(tokenAddress);
      // subtract Ching token from the account
      require(tokenEscrow[tokenAddress][from] >= amount);
      if ( token.transfer(to, amount) ) {
        tokenEscrow[tokenAddress][from] -= amount;
      } else{
        revert();
      }
      TokenWithdrawn(tokenAddress, from, to, amount);      
      // TODO[Phase 2]: hold miner stake till expirations
    }
    function withdrawEther(address from, address to, uint256 amount) private {
      // subtract Ching token from the account
      require(escrow[from] >= amount);
      if ( to.send(amount) ) {
        escrow[from] -= amount;
      } else{
        revert();
      }     
      EtherWithdrawn(from, to, amount);
      // TODO[Phase 2]: hold miner stake till expirations
    }

    // TODO[Phase 2]: miner need to stake before can approval
    // function stake() {
      
    // }

    function getWithdrawNumApprovals(bytes32 txhash) public view returns (uint256){
      return confirmations[txhash].count;
    }
    function getWithdrawTxId(bytes32 txhash) public view returns (string){
      return confirmations[txhash].txId;
    }
    function getWithdrawSeq(bytes32 txhash) public view returns (uint256){
      return confirmations[txhash].seq;
    }
    function getWithdrawFrom(bytes32 txhash) public view returns (address){
      return confirmations[txhash].from;
    }
    function getWithdrawTo(bytes32 txhash) public view returns (address){
      return confirmations[txhash].to;
    }
    function getWithdrawAmount(bytes32 txhash) public view returns (uint256){
      return confirmations[txhash].amount;
    }
    function getWithdrawStatus(bytes32 txhash) public view returns (bool){
      return confirmations[txhash].withdrawn;
    }

    // get approver count
    function getApproverCount(bytes32 txhash) public view returns (uint256){
      return confirmations[txhash].approvers.length;
    }
    // get approver i txId
    function getApproverTxId(bytes32 txhash, uint256 i) public view returns (string){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].txId;
    }
    // get approver i seq
    function getApproverSeq(bytes32 txhash, uint256 i) public view returns (uint256){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].seq;
    }
    // get approver i from
    function getApproverFrom(bytes32 txhash, uint256 i) public view returns (address){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].from;
    }
    // get approver i to
    function getApproverTo(bytes32 txhash, uint256 i) public view returns (address){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].to;
    }
    // get approver i amount
    function getApproverAmount(bytes32 txhash, uint256 i) public view returns (uint256){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].amount;
    }
    // get approver i confirmed
    function getApproverConfirmed(bytes32 txhash, uint256 i) public view returns (bool){
      address approver = confirmations[txhash].approvers[i];
      return confirmations[txhash].approvers_mask[approver].confirmed;
    }
}
