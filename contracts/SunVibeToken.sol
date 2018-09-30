/**
 *  Legal Disclaimer
 *
 *  The content of this contract is written for a CoderSchool.vn event and
 *  educational purposes only.
 *  Financial Poise does not make any guarantee or other promise as to any
 *  results that may be obtained from using this content. No one should make
 *  any investment decision without first consulting his or her own financial
 *  advisor and conducting his or her own research and due diligence.
 */


pragma solidity ^0.4.24;
import "./SafeMath.sol";

/**
 * ERC Token Standard #20 Interface
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
 * Owned contract
 */
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}


/**
 * @title Trading nterface for SunVibeToken
 */
interface TradingSunVibeTokenI {
    function dueDateProcess() external payable; //pricess interst repay
    function setEtherPrice(uint _etherPrice) external; // set one ETH price in Token
    function getBids() view external returns (uint[]); // get list of bids
    function getAsks() view external returns (uint[]); // get list of asks
    function addBid(uint _eth, uint _unitPrice) external; // offer Token for ETH. add a bid record to list
    function fokBid(uint _eth, uint _unitPrice) external; // buy ether now or revert. exec exchange
    function addAsk(uint _unitPrice) payable external; // ask Tocken for ETH. add an ask record to list
    function fokAsk(uint _unitPrice) payable external; // sell ETH now or revert. exec exchange
    function delBid(uint _eth, uint _unitPrice) external; // cancel bid of msg.sender
    function delAsk(uint _eth, uint _unitPrice) external; // cancel ask of msg.sender
}


/**
 * ERC20 Token, with the addition of symbol, name and decimals
 * Receives ETH and generates tokens
 */
contract SunVibeToken is ERC20Interface, Owned, TradingSunVibeTokenI {
  using SafeMath for uint; // solity directive using A for B;
  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;
  mapping(address => uint) balances;
  address[] balanceDict;
  mapping(address => mapping(address => uint)) allowed;

  uint public etherPrice; // current ETH price in Token
  struct bid{uint eth; uint unitPrice; address owner; }
  struct ask{uint eth; uint unitPrice; address owner; }
  mapping (uint => bid) bids;
  mapping (uint => ask) asks;
  address[] bidDict;
  address[] askDict;


  /**
   * @dev The constructor responsible to set the owner and reset variables.
   */
  constructor() public {
    symbol = "SVT";
    name = "SunVibeToken";
    decimals = 18;
    _totalSupply = 0;
    balances[owner] = _totalSupply;
    etherPrice = 75; //initial price
    emit Transfer(address(0), owner, _totalSupply);
  }

  /**
   * @dev returns total supply
   */
  function totalSupply() public constant returns (uint) {
      return _totalSupply - balances[address(0)];
  }

  /**
   * @dev returns the token balance for account `tokenOwner`
   */
  function balanceOf(address tokenOwner) public constant returns (uint balance) {
      return balances[tokenOwner];
  }

  /**
   * @dev removes owner form the dict if no more token left
   */
  function cleanUpBalanceDict(address vacant) internal{
    if (balances[msg.sender] == 0) {
      for (uint i=0; i<balanceDict.length; i++) {
        if (balanceDict[i]==vacant) {
          balanceDict[i] = 0;
          return;
        }
      }
    }
  }

  /**
   * @dev appends the account to the balance dictionary, vacant indexes will be reused
   */
  function appendBalanceDict(address account) internal{
    bool foundIndex = false;
    uint i=0;
    for (; i<balanceDict.length; i++) {
      if (balanceDict[i]==account) {
        return;
      }
      if (balanceDict[i]==0) {
        foundIndex = true;
        break;
      }
    }
    if (foundIndex) {
      balanceDict[i] = account;
    } else {
      balanceDict.push(account);
    }
  }

  /**
   * @dev transfers the balance from token owner's account to `to` account
   * - owner's account must have sufficient balance to transfer
   * - 0 value transfers are allowed
   */
  function transfer(address to, uint tokens) public returns (bool success) {
    require(tokens <= balances[msg.sender]);
    require(to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    cleanUpBalanceDict(msg.sender);
    balances[to] = balances[to].add(tokens);
    appendBalanceDict(to);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  /**
   * @dev Token owner can approve for `spender` to transferFrom(...) `tokens`
   * from the token owner's account
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
   * recommends that there are no checks for the approval double-spend attack
   * as this should be implemented in user interfaces
   */
  function approve(address spender, uint tokens) public returns (bool success) {
    require(spender != address(0));
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  /**
   * @dev transfers `tokens` from the `from` account to the `to` account
   * the calling account must already have sufficient tokens approve(...)-d
   * for spending from the `from` account and
   * - from account must have sufficient balance to transfer
   * - spender must have sufficient allowance to transfer
   * - 0 value transfers are allowed
   */
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    require(tokens <= balances[from]);
    require(tokens <= allowed[from][msg.sender]);
    require(to != address(0));
    balances[from] = balances[from].sub(tokens);
    cleanUpBalanceDict(from);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    appendBalanceDict(to);
    emit Transfer(from, to, tokens);
    return true;
  }

  /**
   * @dev returns the amount of tokens approved by the owner that can be
   * transferred to the spender's account
   */
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  /**
   * @dev accepts ETH and debits token
   */
  function () public payable {
    uint tokens;
    tokens = msg.value * etherPrice;
    balances[msg.sender] = balances[msg.sender].add(tokens);
    _totalSupply = _totalSupply.add(tokens);
    emit Transfer(address(0), msg.sender, tokens);
    owner.transfer(msg.value);
  }

  /**
   * owner can transfer out any accidentally sent ERC20 tokens
   */
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

  /**
   * @dev process instrument becomes due and the insterest is repaid to the investor
   */
  function dueDateProcess() public payable {

  }

  /**
   * @dev sets one ETH price in Token by owner
   * applied only for the new token creation
   * the marketplace freely ignore this
   */
  function setEtherPrice(uint _etherPrice) external onlyOwner {
    etherPrice = _etherPrice;
  }

  /**
   * @dev Returns active bids, uncluded vacants [eth1, amount1, eth2, amount2, ...]
   */
  function getBids() view external returns (uint[]) {
    uint l = bidDict.length;
    uint[] memory _bids = new uint[](l * 2);
    for (uint i=0; i<l; i++) {
      _bids[i*2] = bids[i].eth;
      _bids[i*2+1] =  bids[i].unitPrice;
    }
    return _bids;
  }


  /**
   * @dev Returns active asks, uncluded vacants [eth1, amount1, eth2, amount2, ...]
   */
  function getAsks() view external returns (uint[]) {
    uint l = askDict.length;
    uint[] memory _asks = new uint[](l * 2);
    for (uint i=0; i<l; i++) {
      _asks[i*2] = asks[i].eth;
      _asks[i*2+1] =  asks[i].unitPrice;
    }
    return _asks;
  }

  /**
   * @dev Adds a bid record to list by offering Token for ETH
   */
  function addBid(uint _eth, uint _unitPrice) external {
    require(_eth > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    uint inToken;
    inToken = _eth.mul(_unitPrice);
    require(balances[msg.sender] >= inToken, "Insufficient token!");
    balances[msg.sender] = balances[msg.sender].sub(inToken);
    cleanUpBalanceDict(msg.sender);
    // add the bid to the bid dictionary, vacant indexes will be reused
    bool foundIndex = false;
    uint i=0;
    bid memory _bid;
    for (; i<bidDict.length; i++) {
      if (bidDict[i]==0) {
        foundIndex = true;
        break;
      }
    }
    if (foundIndex) {
      bidDict[i] = msg.sender;
    } else {
      i = bidDict.push(msg.sender) - 1;
    }
    _bid.eth = _eth;
    _bid.unitPrice = _unitPrice;
    _bid.owner = msg.sender;
    bids[i] = _bid;
  }

  /**
   * @dev FOK (fill or kill) bid. Must have a matching ask for the total amount to succed.
   */
  function fokBid(uint _eth, uint _unitPrice) public {
    require(_eth > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    uint e = _eth;
    uint t = e.mul(_unitPrice);
    require(balances[msg.sender] >= t, "Insufficient token!");
    uint l = askDict.length;
    address o;
    for (uint i=0; i<l; i++) {
      if (_unitPrice == asks[i].unitPrice) {
        o = asks[i].owner;
        if (e >= asks[i].eth) {
          e = asks[i].eth;
          t = e.mul(_unitPrice);
          asks[i].eth = 0;
          asks[i].unitPrice = 0;
          asks[i].owner = 0;
          askDict[i] = 0;
        } else {
          asks[i].eth = asks[i].eth.sub(e);
        }
        balances[msg.sender] = balances[msg.sender].sub(t);
        cleanUpBalanceDict(msg.sender);
        msg.sender.transfer(e);
        balances[0] = balances[0].add(t);
        if (e < _eth) {
          fokBid(_eth.sub(e), _unitPrice);
        }
        return;
      }
    }
    revert("No matching asks!");
  }

  /**
   * @dev Adds an ask record to list by asking Token for ETH
   */
  function addAsk(uint _unitPrice) payable external {
    require(msg.value > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    // add the ask to the ask dictionary, vacant indexes will be reused
    bool foundIndex = false;
    uint i=0;
    ask memory _ask;
    for (; i<askDict.length; i++) {
      if (askDict[i]==0) {
        foundIndex = true;
        break;
      }
    }
    if (foundIndex) {
      askDict[i] = msg.sender;
    } else {
      i = askDict.push(msg.sender) - 1;
    }
    _ask.eth = msg.value;
    _ask.unitPrice = _unitPrice;
    _ask.owner = msg.sender;
    asks[i] = _ask;
  }


  /**
   * @dev FOK (fill or kill) ask. Must have a matching bid for the total amonut to succed.
   */
  function fokAskRecursion(uint _eth, uint _unitPrice) internal {
    require(msg.value > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    uint e = _eth;
    uint t = e.mul(_unitPrice);
    uint l = bidDict.length;
    address o;
    for (uint i=0; i<l; i++) {
      if (_unitPrice == bids[i].unitPrice) {
        o = bids[i].owner;
        if (e >= bids[i].eth) {
          e = bids[i].eth;
          t = e.mul(_unitPrice);
          bids[i].eth = 0;
          bids[i].unitPrice = 0;
          bids[i].owner = 0;
          bidDict[i] = 0;
        } else {
          bids[i].eth = bids[i].eth.sub(e);
        }
        balances[msg.sender] = balances[msg.sender].add(t);
        o.transfer(e);
        if (e < _eth) {
          fokAskRecursion(_eth.sub(e), _unitPrice);
        }
        return;
      }
    }
    revert("No matching bids!");
  }


  /**
   * @dev FOK (fill or kill) ask. Must have a matching bid for the total amonut to succed.
   */
  function fokAsk(uint _unitPrice) payable public {
    require(msg.value > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    fokAskRecursion(msg.value, _unitPrice);
  }

  /**
   * @dev removes one matching bid from the bid dictionary and debit the token
   */
  function delBid(uint _eth, uint _unitPrice) external  {
    require(_eth > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    uint l = bidDict.length;
    for (uint i=0; i<l; i++) {
      if (_eth == bids[i].eth && _unitPrice == bids[i].unitPrice && msg.sender == bids[i].owner) {
        bids[i].eth = 0;
        bids[i].unitPrice = 0;
        bids[i].owner = 0;
        bidDict[i] = 0;
        balances[bids[i].owner] = balances[bids[i].owner].add(_eth.mul(_unitPrice));
        return;
      }
    }
    revert("No matching bids!");
  }

  /**
   * @dev removes one matching ask from the ask dictionary and return the ethereum
   */
  function delAsk(uint _eth, uint _unitPrice) external  {
    require(_eth > 0 && _unitPrice > 0, "ETH and unitPrice must be more than zero!");
    uint l = askDict.length;
    for (uint i=0; i<l; i++) {
      if (_eth == asks[i].eth && _unitPrice == asks[i].unitPrice && msg.sender == asks[i].owner) {
        asks[i].eth = 0;
        asks[i].unitPrice = 0;
        asks[i].owner = 0;
        askDict[i] = 0;
        asks[i].owner.transfer(_eth);
        return;
      }
    }
    revert("No matching asks!");
  }
}
