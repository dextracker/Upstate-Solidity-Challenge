const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("TimeLockTransfer Token and Contribution Contract", function() {
  let TLT,token, tokenFail,owner, addr1,addr2, startTime, endTime, amount;
  let contributionContract,contribution, minter;

  beforeEach(async () => {
   TLT = await ethers.getContractFactory("TimeLockTransferToken");
   contributionContract = await ethers.getContractFactory("Contribution");
   [owner, addr1,addr2] = await ethers.getSigners();
   startTime = Number(Date.now()/1000).toFixed(); //timestamp in unix readable format   
   endTime = Number(startTime) + 86400; //one day in unix ts
   startTimeFail = Number(endTime);
   endTimeFail =Number(startTimeFail) + 86400;
   amount = 50; // amount of tokens to transfer
  })
  
  describe("Time Lock Token Deployment", () => {
    it("Should  deploy token and return the token details", async function() {
      token = await TLT.deploy(1000,startTime, endTime); //deploy with 1000 tokens
      
      await token.deployed();

      expect(await token.name()).to.equal("TimeLockTransfer");
      expect(await token.symbol()).to.equal("TLT");
      expect(await token.totalSupply()).to.equal(1000);
      expect(await token.startTime()).to.equal(startTime);
      expect(await token.endTime()).to.equal(endTime);
      expect(await token.owner()).to.equal(owner.address);
      expect(await token.balanceOf(owner.address)).to.equal(1000);
    });
    
  });

  describe("Contribution Deployment", () => {
    it("Should Deploy Contribution and set Minter", async function() {
      //console.log(token.address);
      contribution = await contributionContract.deploy(token.address);
      await contribution.deployed();
      //console.log(contribution.address);
      
      await token.setMinter(contribution.address);
      minter = contribution.address;
      expect(await token.minter()).to.equal(minter)
    });

    it("Should deposit ETH to contribution and mint tokens for addr2", async function() {
      let contributionAmount = 10;
      let contributtionAddr2 = await contribution.connect(addr2);
      //console.log(addr2);
      //console.log(contributtionAddr2);
      await contributtionAddr2.deposit({value: contributionAmount});
      
      expect(await contribution.getContribution(addr2.address)).to.equal(contributionAmount);
      

    })
    it("Should emit Deposit event", async function() {
      contribution.on("Deposit", (contributor, value) => {
        expect(contributor).to.equal(addr2.address);        
        expect(value).to.equal(contributionAmount);
      })
    })

    it("Should emit TokensMinted event", async function() {
      contribution.on("TokensMinted", (contributor, value) => {
        expect(contributor).to.equal(addr2.address);        
        expect(value).to.equal(contributionAmount);
      })
    })
  });

describe("Token Transfer", () => {
    it("Should transfer 50 tokens from owner to addr1", async function(){
      // expect(await token.startTime()).to.lessThanOrEqual(startTime);
      // expect(await token.endTime()).to.lessThanOrEqual(endTime);
      expect(await token.canTransfer()).to.equal(true);

      let transfer = await token.transfer(addr1.address, 50);
      await transfer.wait();

      const balAddr1 = await token.balanceOf(addr1.address);
      const balOwner = await token.balanceOf(owner.address);
      
      expect(balAddr1).to.equal(50);
      expect(balOwner).to.equal(950);
    });
    it("Should emit transfer event", async function() {
      token.on("Transfer", (from, to, value) => {
        expect(from).to.equal(owner);
        expect(to).to.equal(addr1);
        expect(value).to.equal(amount);
      })
    })

  });

  describe("Failed Token Transfer", () => {
    
    it("Should not be able to transfer tokens because of start time", async function() {
      tokenFail = await TLT.deploy(1000, startTimeFail, endTimeFail); //deploy with 1000 tokens
      await tokenFail.deployed();

      let start = await tokenFail.startTime();
      let end = await tokenFail.endTime();      
      expect(await tokenFail.canTransfer()).to.equal(false);
    })

    it("Should revert when we try to perform transfer", async function() {
      let originalBalAddr1 = await tokenFail.balanceOf(addr1.address);
      let originalBalOwner = await tokenFail.balanceOf(owner.address);
      
      await expect(tokenFail.transfer(addr1.address, 50)).to.be.revertedWith("The transfers period has not started.");    

      let balAddr1 = await tokenFail.balanceOf(addr1.address);
      let balOwner = await tokenFail.balanceOf(owner.address);
      
      expect(balAddr1).to.equal(originalBalAddr1);
      expect(balOwner).to.equal(originalBalOwner);
    })

  })

});
