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
 * ERC20 Token, with the addition of symbol, name and decimals
 * Receives ETH and generates tokens
 */
contract SunVibeToken is ERC20Interface, Owned {
  using SafeMath for uint; // solity directive using A for B;
  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  /**
   * @dev The constructor responsible to set the owner and reset variables.
   */
  constructor() public {
    symbol = "SVT";
    name = "SunVibeToken";
    decimals = 18;
    _totalSupply = 0;
    balances[owner] = _totalSupply;
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
   * @dev transfers the balance from token owner's account to `to` account
   * - owner's account must have sufficient balance to transfer
   * - 0 value transfers are allowed
   */
  function transfer(address to, uint tokens) public returns (bool success) {
    require(tokens <= balances[msg.sender]);
    require(to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
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
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
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
    tokens = msg.value * 75;
    balances[msg.sender] = balances[msg.sender].add(tokens);
    _totalSupply = _totalSupply.add(tokens);
    emit Transfer(address(0), msg.sender, tokens);
    owner.transfer(msg.value);
  }

  /**
   * @dev process instrument becomes due and the insterest is repaid to the investor
   */
  function dueDateProcess() public payable returns (bool success) {
    return true;
  }

  /**
   * owner can transfer out any accidentally sent ERC20 tokens
   */
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}
