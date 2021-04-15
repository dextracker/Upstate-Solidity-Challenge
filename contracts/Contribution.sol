pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./TimeLockTransfer.sol";

///@notice an Interface to mint tokens from the TimeLockTransferToken Contract
abstract contract ITimeLockTransfer {
    function mintForContribution(address contributor, uint256 amount) public virtual;
}

///@title A time locked token contract that cannot be transfered until a specified startTime and endTime
///@author Noah Khamliche
contract Contribution {
 mapping(address => uint256) private contributions;
 
 ///@dev a interface reference to the TimeLockTransfer Contract
 ITimeLockTransfer TimeLockTransfer;

 ///@notice Deposit event fired when a successful deposit occurs
 event Deposit(address indexed contributor, uint256 amount);
 ///@notice TokensMinted event fired when a successful minting occurs
 event TokensMinted(address indexed contributor, uint256 amount);
 
 ///@notice creates the Contribution contract with the address of the TimeLockTransfer Contract
 ///@dev TimeLockTransfer contract must be deployed before deploying this contract
 constructor(address TLT){
    TimeLockTransfer = ITimeLockTransfer(TLT);
 }
 

 ///@notice Deposits ETH into the contract and mints tokens to the sender of the transaction
  function deposit() payable public {
    uint256 amount = msg.value;
    require(amount > 0, "No ETH sent.");//also functions as -1 undeflow error so attackers cant mint the max amount of tokens;
    
    contributions[msg.sender] += amount;
    emit Deposit(msg.sender, amount);
    
    mint(msg.sender, amount);
 }

 ///@notice returns the amount of eth supplied to the deposit function by a given address
 function getContribution(address _address) public view returns (uint256 amount){
    return contributions[_address];
 }
 
 ///@notice mints tokens to the contributor based on the amount of ETH supplied
 ///@dev Internal function must be called by the deposit function, not directly
 function mint(address contributor, uint256 amount) internal returns (bool success){
     TimeLockTransfer.mintForContribution(contributor, amount);
     emit TokensMinted(contributor, amount);
     return true;
 }
    
}