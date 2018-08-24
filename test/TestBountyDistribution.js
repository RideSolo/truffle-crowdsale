import ether from './helpers/ether';
import {
  advanceBlock
} from './helpers/advanceToBlock.js';
import increaseTimeTo from './helpers/increaseTime.js';
import latestTime from './helpers/latestTime.js';
import EVMRevert from './helpers/EVMRevert.js';

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();
const CALLGToken = artifacts.require("./CALLGToken.sol");
const CALLToken = artifacts.require("./CALLToken.sol");
const BountyVault = artifacts.require("./BountyVault.sol");
const CapitalBountyDelivery = artifacts.require("./CapitalBountyDelivery.sol");
const CapitalTechCrowdsale = artifacts.require("./CapitalTechCrowdsale.sol");
const parameters = require('./local_parameters.json');

contract("TestBountyDistribution", function([owner, wallet, investor, bounty1, bounty2, bounty3, bounty4, bounty5, bounty6, bounty7]) {
  before(async function() {
    await advanceBlock();
    this.crowdsale = await CapitalTechCrowdsale.deployed();
	this.bounty_delivery = await CapitalBountyDelivery.deployed();
    this.bounty = BountyVault.at(await this.crowdsale.bountyVault());	
    this.call_token = CALLToken.at(await this.crowdsale.token_call());
    this.callg_token = CALLGToken.at(await this.crowdsale.token_callg());
  });

  beforeEach(async function() {
    await advanceBlock();
  });

  it("The Bounty Vault contract should be deployed and have required supply", async function() {
    this.bounty.should.exist;
	await this.crowdsale.distributeBounty({from: owner});

    const address = await this.crowdsale.bountyVault();
    const balance_call = await this.call_token.balanceOf.call(address);
    const balance_callg = await this.callg_token.balanceOf.call(address);

    balance_call.div(1e18).toNumber().should.be.equal(2625000);
    balance_callg.div(1e18).toNumber().should.be.equal(525000000);
  });
  
  it("The CapitalBountyDelivery contract should be deployed", async function() {
    this.bounty_delivery.should.exist;
  });

  it("The Bounty Vault contract should send tokens to Bounty Delivery contract", async function() {
    await this.crowdsale.withdrawBounty(this.bounty_delivery.address, {
      from: owner
    });

    const balance = await this.call_token.balanceOf.call(this.bounty_delivery.address);
    const balance_callg = await this.callg_token.balanceOf.call(this.bounty_delivery.address);

    balance.div(1e18).toNumber().should.be.equal(2625000);
    balance_callg.div(1e18).toNumber().should.be.equal(525000000);
  });
  it("The contract should be able to send from the first Bounty stage", async function() {
    const amount = 1000;
	
	await this.bounty_delivery.sendFirst(wallet, amount, {
      from: owner
    });

    const balance = await this.call_token.balanceOf.call(wallet);
    const balance_callg = await this.callg_token.balanceOf.call(wallet);

    balance.div(1e18).toNumber().should.be.equal(amount);
    balance_callg.div(1e18).toNumber().should.be.equal(amount * 200);
  });
  
  it("The contract should be able to send in batch from the first Bounty stage", async function() {
	await this.bounty_delivery.sendFirstBatch([bounty1, bounty2, bounty3, bounty4], [100, 200, 300, 400], {
      from: owner
    });

    const balance_1 = await this.call_token.balanceOf.call(bounty1);
    const balance_1_callg = await this.callg_token.balanceOf.call(bounty1);
	const balance_2 = await this.call_token.balanceOf.call(bounty2);
    const balance_2_callg = await this.callg_token.balanceOf.call(bounty2);
	const balance_3 = await this.call_token.balanceOf.call(bounty3);
    const balance_3_callg = await this.callg_token.balanceOf.call(bounty3);
	const balance_4 = await this.call_token.balanceOf.call(bounty4);
    const balance_4_callg = await this.callg_token.balanceOf.call(bounty4);
	
    balance_1.div(1e18).toNumber().should.be.equal(100);
    balance_1_callg.div(1e18).toNumber().should.be.equal(20000);
	balance_2.div(1e18).toNumber().should.be.equal(200);
    balance_2_callg.div(1e18).toNumber().should.be.equal(40000);
	balance_3.div(1e18).toNumber().should.be.equal(300);
    balance_3_callg.div(1e18).toNumber().should.be.equal(60000);
	balance_4.div(1e18).toNumber().should.be.equal(400);
    balance_4_callg.div(1e18).toNumber().should.be.equal(80000);
	
	increaseTimeTo(1538179300);
  });
  
  it("The contract should be able to send from the second Bounty stage", async function() {
    const amount = 2000;
	
	await this.bounty_delivery.sendSecond(investor, amount, {
      from: owner
    });

    const balance = await this.call_token.balanceOf.call(investor);
    const balance_callg = await this.callg_token.balanceOf.call(investor);

    balance.div(1e18).toNumber().should.be.equal(amount);
    balance_callg.div(1e18).toNumber().should.be.equal(amount * 200);	
  });
  
  it("The contract should be able to send in batch from the second Bounty stage", async function() {
	await this.bounty_delivery.sendSecondBatch([bounty5, bounty6, bounty7], [500, 600, 700, 800], {
      from: owner
    });

    const balance_5 = await this.call_token.balanceOf.call(bounty5);
    const balance_5_callg = await this.callg_token.balanceOf.call(bounty5);
	const balance_6 = await this.call_token.balanceOf.call(bounty6);
    const balance_6_callg = await this.callg_token.balanceOf.call(bounty6);
	const balance_7 = await this.call_token.balanceOf.call(bounty7);
    const balance_7_callg = await this.callg_token.balanceOf.call(bounty7);
	
    balance_5.div(1e18).toNumber().should.be.equal(500);
    balance_5_callg.div(1e18).toNumber().should.be.equal(100000);
	balance_6.div(1e18).toNumber().should.be.equal(600);
    balance_6_callg.div(1e18).toNumber().should.be.equal(120000);
	balance_7.div(1e18).toNumber().should.be.equal(700);
    balance_7_callg.div(1e18).toNumber().should.be.equal(140000);
  });
  
  it("The contract should allow admin to be withdraw remaining tokens", async function() {
    await this.bounty_delivery.withdrawTokens(owner, {
      from: owner
    });

    const balance = await this.call_token.balanceOf.call(owner);
    const balance_callg = await this.callg_token.balanceOf.call(owner);

    balance.div(1e18).toNumber().should.be.equal(2619200);
    balance_callg.div(1e18).toNumber().should.be.equal(523840000);
  });
});
