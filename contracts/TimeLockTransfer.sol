//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

///@title A time locked token contract that cannot be transfered until a specified startTime and endTime
///@author Noah Khamliche

contract TimeLockTransferToken is ERC20 {
  uint256 public startTime;
  uint256 public endTime;
  address public owner;
  mapping(address => uint) private balances;
  address public minter;

  ///@notice the Transfer event to be fired when a successful transfer occurs
  event _Transfer( address indexed from, address indexed to, uint amount);
  

  ///@notice creates a token with an initial supply and a specified transfer window.
  constructor(uint256 initialSupply, uint256 _startTime, uint256 _endTime) ERC20("TimeLockTransfer", "TLT"){
    require(_startTime < _endTime, "Invalid args, startTime > endTime");
    _mint(msg.sender, initialSupply);
    balances[msg.sender] = initialSupply;
    owner = msg.sender;
    startTime = _startTime;
    endTime = _endTime;
  }
  
  ///@notice ovverriden balanceOf function to return the amount of tokens held by a particualr address
  ///@dev returns the balance of the address provided
  function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
  }

  ///@notice ovverriden transfer function to account for startTime and endTime in the constructor
  ///@dev returns true if the transfer is successful  
  function transfer(address to, uint amount) public virtual override returns(bool){
      uint senderInitialBal;
      uint recipientInitialBal;
      uint timestamp = block.timestamp;
      require(timestamp >= startTime, "The transfers period has not started.");
      require(timestamp <= endTime, "The transfer period has expired.");
      require(balances[msg.sender] >= amount, "You do not have enough tokens to perform this transfer");
      
      balances[msg.sender] -= amount;
      balances[to] += amount;
      senderInitialBal = balances[msg.sender];
      recipientInitialBal = balances[to];
      
      require(balances[msg.sender] == senderInitialBal, "Unsuccessful token transfer, revert...");
      require(balances[to] == recipientInitialBal, "Unsuccessful token transfer, revert...");
      emit _Transfer(msg.sender, to, amount);
      return true;
  }
  
  ///@notice Checks if the token can be transfered during the current block
  ///@dev returns true if token can be transfered, returns false if it cannot
  function canTransfer() public view returns(bool){
    if(block.timestamp >= startTime && block.timestamp <= endTime ){
        return true;
    }    
    else{
        return false;
    }
  
  }
  
  ///@notice Sets the minting contract for the Contribution contract so that tokens can be minted from an external contract
  ///@dev can only be set by the owner of the token contract
  function setMinter(address _minter) public {
      require(msg.sender == owner);
      minter = _minter;
  }

  ///@notice Mints an equivalent amount of tokens to the amount of eth supplied
  ///@dev can only be called by the minting contract  
  function mintForContribution(address contributor, uint amount) public {
      require(msg.sender == minter, "Only the Contribution contract can access this function.");
      _mint(contributor, amount);
      balances[contributor] += amount;
  }
  
}