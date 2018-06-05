import ether from './helpers/ether';
import {
  advanceBlock
} from './helpers/advanceToBlock.js';
import {
  increaseTimeTo,
  duration
} from './helpers/increaseTime.js';
import latestTime from './helpers/latestTime.js';
import EVMRevert from './helpers/EVMRevert.js';

const BigNumber = web3.BigNumber;
require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();
const FiatContract = artifacts.require("./FiatContract.sol")
const CALLGToken = artifacts.require("./CALLGToken.sol");
const CALLToken = artifacts.require("./CALLToken.sol");
const CapitalTechCrowdsale = artifacts.require("./CapitalTechCrowdsale.sol");

contract("CapitalTechCrowdsale", function([owner, wallet, investor, otherInvestor]) {
  before(async function() {
    await advanceBlock();
  });

  beforeEach(async function() {

    this.crowdsale = await CapitalTechCrowdsale.new(owner, FiatContract.address, CALLToken.address, CALLGToken.address);

    this.call_token = CALLToken.at(await this.crowdsale.token_call());
    this.callg_token = CALLGToken.at(await this.crowdsale.token_callg());

    await this.crowdsale.powerUpContract();
  });

  it("The crowdsale should be started with correct parameters", async function() {
    this.crowdsale.should.exist;
    this.call_token.should.exist;
    this.callg_token.should.exist;

    const startTime = await this.crowdsale.startTime();
    const endTime = await this.crowdsale.endTime();
    const crowdsaleWallet = await this.crowdsale.wallet();
    const vaultWallet = await this.crowdsale.vault();

    console.log(owner);
    console.log(investor);
    console.log(crowdsaleWallet);
    console.log(vaultWallet);

    //startTime.should.be.bignumber.greaterThan(this.now);
    //crowdsaleWallet.should.be.equal(owner);
  });

  it("The crowdsale should be started", async function() {
    let instance = await CapitalTechCrowdsale.deployed();
    let ended = await instance.hasEnded.call();

    assert.equal(ended, false, "The crowdsale has started");
  });

  it("Buy", async function() {
    let instance = await CapitalTechCrowdsale.deployed();
    let purchase = await instance.buyTokens(investor, {from: investor, value: 100000000000000000});

    assert.equal(purchase.logs.length, 1, "The coins were minted");
  });
});
