/*
Capital Technologies & Research - Capital (CALL) & CapitalGAS (CALLG) - Crowdsale Smart Contract
https://www.mycapitalco.in
*/
pragma solidity 0.4.24;

import './CALLGToken.sol';
import './CALLToken.sol';
import './TeamVault.sol';
import './BountyVault.sol';
import 'openzeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol';
contract FiatContract {
  function USD(uint _id) public constant returns (uint256);
}
contract CapitalTechCrowdsale is Ownable {
  using SafeMath for uint256;
  ERC20 public token_call;
  ERC20 public token_callg;
  FiatContract public fiat_contract;
  RefundVault public vault;
  TeamVault public teamVault;
  BountyVault public bountyVault;
  enum stages { PRIVATE_SALE, PRE_SALE, MAIN_SALE_1, MAIN_SALE_2, MAIN_SALE_3, MAIN_SALE_4, FINALIZED }
  address public wallet;
  uint256 public maxContributionPerAddress;
  uint256 public stageStartTime;
  uint256 public weiRaised;
  uint256 public minInvestment;
  stages public stage;
  bool public is_finalized;
  bool public powered_up;
  bool public distributed_team;
  bool public distributed_bounty;
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public userHistory;
  mapping(uint => uint) public stages_duration;
  uint256 public callSoftCap;
  uint256 public callgSoftCap;
  uint256 public callDistributed;
  uint256 public callgDistributed;
  uint256 public constant decimals = 18;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount_call, uint256 amount_callg);
  event TokenTransfer(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount_call, uint256 amount_callg);
  event StageChanged(stages stage, stages next_stage, uint stageStartTime);
  event GoalReached(uint callSoftCap, uint callgSoftCap);
  event Finalized(uint callDistributed, uint callgDistributed);
  function () external payable {
    buyTokens(msg.sender);
  }
  constructor(address _wallet, address _fiatcontract, ERC20 _token_call, ERC20 _token_callg) public {
    require(_token_call != address(0));
    require(_token_callg != address(0));
    require(_wallet != address(0));
    require(_fiatcontract != address(0));
    token_call = _token_call;
    token_callg = _token_callg;
    wallet = _wallet;
    fiat_contract = FiatContract(_fiatcontract);
    vault = new RefundVault(_wallet);
    bountyVault = new BountyVault(_token_call, _token_callg);
    teamVault = new TeamVault(_token_call, _token_callg);
  }
  function powerUpContract() public onlyOwner {
    require(!powered_up);
    require(!is_finalized);
    stageStartTime = block.timestamp;
    stage = stages.PRIVATE_SALE;
    weiRaised = 0;
  	distributeTeam();
  	distributeBounty();
	  callDistributed = 7875000 * 10 ** decimals;
    callgDistributed = 1575000000 * 10 ** decimals;
    callSoftCap = 18049500 * 10 ** decimals;
    callgSoftCap = 3609900000 * 10 ** decimals;
    //maxContributionPerAddress = 1500 ether;
    maxContributionPerAddress = 150000 ether;
    minInvestment = 0.01 ether;
    is_finalized = false;
    powered_up = true;
    stages_duration[uint(stages.PRIVATE_SALE)] = 30 days;
    stages_duration[uint(stages.PRE_SALE)] = 30 days;
    stages_duration[uint(stages.MAIN_SALE_1)] = 7 days;
    stages_duration[uint(stages.MAIN_SALE_2)] = 7 days;
    stages_duration[uint(stages.MAIN_SALE_3)] = 7 days;
    stages_duration[uint(stages.MAIN_SALE_4)] = 7 days;
  }
  function distributeTeam() public onlyOwner {
    require(!distributed_team);
    uint _amount = 5250000 * 10 ** decimals;
    distributed_team = true;
    MintableToken(token_call).mint(teamVault, _amount);
    MintableToken(token_callg).mint(teamVault, _amount.mul(200));
    emit TokenTransfer(msg.sender, teamVault, _amount, _amount, _amount.mul(200));
  }
  function distributeBounty() public onlyOwner {
    require(!distributed_bounty);
    uint _amount = 2625000 * 10 ** decimals;
    distributed_bounty = true;
    MintableToken(token_call).mint(bountyVault, _amount);
    MintableToken(token_callg).mint(bountyVault, _amount.mul(200));
    emit TokenTransfer(msg.sender, bountyVault, _amount, _amount, _amount.mul(200));
  }
  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }
  function getUserHistory(address _beneficiary) public view returns (uint256) {
    return userHistory[_beneficiary];
  }
  function getReferrals(address[] _beneficiaries) public view returns (address[], uint256[]) {
  	address[] memory addrs = new address[](_beneficiaries.length);
  	uint256[] memory funds = new uint256[](_beneficiaries.length);
  	for (uint i = 0; i < _beneficiaries.length; i++) {
  		addrs[i] = _beneficiaries[i];
  		funds[i] = getUserHistory(_beneficiaries[i]);
  	}
    return (addrs, funds);
  }
  function getAmountForCurrentStage(uint256 _amount) public view returns(uint256) {
    uint256 tokenPrice = fiat_contract.USD(0);
    if(stage == stages.PRIVATE_SALE) {
      tokenPrice = tokenPrice.mul(35).div(10 ** 8);
    } else if(stage == stages.PRE_SALE) {
      tokenPrice = tokenPrice.mul(50).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_1) {
      tokenPrice = tokenPrice.mul(70).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_2) {
      tokenPrice = tokenPrice.mul(80).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_3) {
      tokenPrice = tokenPrice.mul(90).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_4) {
      tokenPrice = tokenPrice.mul(100).div(10 ** 8);
    }
    return _amount.div(tokenPrice).mul(10 ** 10);
  }
  function _getNextStage() internal view returns (stages) {
    stages next_stage;
    if (stage == stages.PRIVATE_SALE) {
      next_stage = stages.PRE_SALE;
    } else if (stage == stages.PRE_SALE) {
      next_stage = stages.MAIN_SALE_1;
    } else if (stage == stages.MAIN_SALE_1) {
      next_stage = stages.MAIN_SALE_2;
    } else if (stage == stages.MAIN_SALE_2) {
      next_stage = stages.MAIN_SALE_3;
    } else if (stage == stages.MAIN_SALE_3) {
      next_stage = stages.MAIN_SALE_4;
    } else {
      next_stage = stages.FINALIZED;
    }
    return next_stage;
  }
  function getHardCap() public view returns (uint, uint) {
    uint hardcap_call;
    uint hardcap_callg;
    if (stage == stages.PRIVATE_SALE) {
      hardcap_call = 10842563;
      hardcap_callg = 2168512500;
    } else if (stage == stages.PRE_SALE) {
      hardcap_call = 18049500;
      hardcap_callg = 3609900000;
    } else if (stage == stages.MAIN_SALE_1) {
      hardcap_call = 30937200;
      hardcap_callg = 6187440000;
    } else if (stage == stages.MAIN_SALE_2) {
      hardcap_call = 40602975;
      hardcap_callg = 8120595000;
    } else if (stage == stages.MAIN_SALE_3) {
      hardcap_call = 47046825;
      hardcap_callg = 9409365000;
    } else {
      hardcap_call = 52500000;
      hardcap_callg = 10500000000;
    }
    return (hardcap_call.mul(10 ** decimals), hardcap_callg.mul(10 ** decimals));
  }
  function updateStage() public {
    _updateStage(0, 0);
  }
  function _updateStage(uint256 weiAmount, uint256 callAmount) internal {
    uint _duration = stages_duration[uint(stage)];
    uint call_tokens = 0;
    if (weiAmount != 0) {
      call_tokens = getAmountForCurrentStage(weiAmount);
    } else {
      call_tokens = callAmount;
    }
    uint callg_tokens = call_tokens.mul(200);
    (uint _hardcapCall, uint _hardcapCallg) = getHardCap();
    if(stageStartTime.add(_duration) <= block.timestamp || callDistributed.add(call_tokens) >= _hardcapCall || callgDistributed.add(callg_tokens) >= _hardcapCallg) {
      stages next_stage = _getNextStage();
      if (next_stage != stages.FINALIZED) {
        emit StageChanged(stage, next_stage, stageStartTime);
        stage = next_stage;
        stageStartTime = block.timestamp;
      } else {
        stage = next_stage;
        finalization();
      }
    }
  }
  function buyTokens(address _beneficiary) public payable {
    require(!is_finalized);
    if (_beneficiary == address(0)) {
      _beneficiary = msg.sender;
    }
    (uint _hardcapCall, uint _hardcapCallg) = getHardCap();
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    require(_beneficiary != address(0));
    require(weiAmount >= minInvestment);
    require(contributions[_beneficiary].add(weiAmount) <= maxContributionPerAddress);
    _updateStage(weiAmount, 0);
    uint256 call_tokens = getAmountForCurrentStage(weiAmount);
    uint256 callg_tokens = call_tokens.mul(200);
    weiRaised = weiRaised.add(weiAmount);
    callDistributed = callDistributed.add(call_tokens);
    callgDistributed = callgDistributed.add(callg_tokens);
    MintableToken(token_call).mint(_beneficiary, call_tokens);
    MintableToken(token_callg).mint(_beneficiary, callg_tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, call_tokens, callg_tokens);
    contributions[_beneficiary] = contributions[_beneficiary].add(weiAmount);
    userHistory[_beneficiary] = userHistory[_beneficiary].add(call_tokens);
    vault.deposit.value(msg.value)(msg.sender);
  }
  function finalize() onlyOwner public {
    finalization();
  }
  function extendPeriod(uint date) public onlyOwner {
    stages_duration[uint(stage)] = stages_duration[uint(stage)].add(date);
  }
  function transferTokens(address _to, uint256 _amount) public onlyOwner {
    require(!is_finalized);
    require(_to != address(0));
    require(_amount > 0);
    _updateStage(0, _amount);
    callDistributed = callDistributed.add(_amount);
    callgDistributed = callgDistributed.add(_amount.mul(200));
    MintableToken(token_call).mint(_to, _amount);
    MintableToken(token_callg).mint(_to, _amount.mul(200));
    userHistory[_to] = userHistory[_to].add(_amount);
    emit TokenTransfer(msg.sender, _to, _amount, _amount, _amount.mul(200));
  }
  function claimRefund() public {
	  address _beneficiary = msg.sender;
    require(is_finalized);
    require(!goalReached());
    userHistory[_beneficiary] = 0;
    vault.refund(_beneficiary);
  }
  function goalReached() public view returns (bool) {
    if (callDistributed >= callSoftCap && callgDistributed >= callgSoftCap) {
      return true;
    } else {
      return false;
    }
  }
  function finalization() internal {
    require(!is_finalized);
    is_finalized = true;
    emit Finalized(callDistributed, callgDistributed);
    if (goalReached()) {
      emit GoalReached(callSoftCap, callgSoftCap);
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }
}
