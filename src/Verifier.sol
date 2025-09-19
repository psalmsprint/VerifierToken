// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

error Verifier__InsufficientBalance();
error Verifier__AllowanceExceeded();
error Verifier__MintingUnauthorized();
error Verifier__ApproveToInvalidAddress();
error Verifier__NoTokenMinted();
error Verifier__MintingToInvalidAddress();
error Verifier__InvalidAddress();
error Verifier__ContractPaused();
error Verifier__IsPaused();
error Verifier__IsUnpaused();
error Verifier__NoTokenBurned();
error Verifier__NotAllowed();

contract Verifier {
	
	bool public s_pause;
	
	address public immutable i_owner;
	
	uint256 public s_totalSupply = 100_000_000 * 1e18;
	
	mapping(address => uint256) public s_balance;
	mapping(address => bool) public s_isHolder;
	mapping(address => mapping(address => uint256)) public s_allowance;
	
	event Transfer(address indexed sender, address indexed receiver, uint256 amount);
	event Approval(address indexed sender, address indexed receiver, uint256 amount);
	event TokenMint(address indexed sender, address indexed receiver, uint256 amount);
	event TokenBurn(address indexed sender, uint256 amount);
	event Paused(address indexed sender);
	event Unpaused(address indexed sender);
	
	constructor(){
		i_owner = msg.sender;
		s_balance[i_owner] = totalSupply();
	}
	
	modifier onlyOwner() {
		if(msg.sender != i_owner){
			revert Verifier__MintingUnauthorized();
		}
		_;
	}
	
	modifier whenUnPaused() {
		
		if(s_pause){
			revert Verifier__ContractPaused();
		}
		_;
	}
	
	modifier ownerOnly(){
		
		if(msg.sender != i_owner){
			revert Verifier__NotAllowed();
		}
		_;
	}
	
	
	function name() public pure returns(string memory){
		return "Verifier";
	}
	
	function symbol() public pure returns(string memory){
		return "VRC";
	}
	
	function decimals() public pure returns(uint8){
		return 18;
	}
	
	function totalSupply() public view returns(uint256) {
		return s_totalSupply;
	}
	
	function balanceOf(address owner) public view returns(uint256){
		return s_balance[owner];
	} 
	
	function transfer(address to, uint256 value) public whenUnPaused returns (bool){
		
		if(to == address(0)){
			revert Verifier__InvalidAddress();
		}
		
		if(s_balance[msg.sender] < value){
			revert Verifier__InsufficientBalance();
		}
		
		s_balance[msg.sender] -= value;
		s_balance[to] += value;
		
		s_isHolder[to] = true;
		
		if(s_balance[msg.sender] == 0){
			s_isHolder[msg.sender] = false;
		}
		else {
			s_isHolder[msg.sender] = true;
		}
		
		emit Transfer(msg.sender, to, value);
		
			return true;
	}
	
	function transferFrom(address from, address to, uint256 value) public whenUnPaused returns (bool){
	
		if (to == address(0)){
			revert Verifier__InvalidAddress();
		}
		
		if (s_balance[from] < value){
			revert Verifier__InsufficientBalance();
		}
		
		if (s_allowance[from][msg.sender] < value){
			revert Verifier__AllowanceExceeded();
		}
		
		s_allowance[from][msg.sender] -= value;
		s_balance[from] -= value;
		s_balance[to] += value;
		
		s_isHolder[to] = true;
		
		if(s_balance[from] == 0){
			s_isHolder[from] = false;
		}
		else{
			s_isHolder[from] = true;
		}
		
		emit Transfer(from, to, value);
			
			return true;
	}
	
	function approve(address spender, uint256 value) public returns (bool){
		if(spender == address(0)){
			revert Verifier__ApproveToInvalidAddress();
		}
		
		s_allowance[msg.sender][spender] = value;
		
		emit Approval(msg.sender, spender, value);
		
			return true;
	}
	
	function allowance(address from, address spender) public view returns (uint256){
		return s_allowance[from][spender];
	}
	
	function mint(address to, uint256 value) public onlyOwner whenUnPaused{
		
		if(to == address(0)){
			revert Verifier__MintingToInvalidAddress();
		}
		
		if(value == 0){
			revert Verifier__NoTokenMinted();
		}
		
		s_balance[to] += value;
		s_totalSupply += value;
		
		s_isHolder[to] = true;
		
		emit Transfer(address(0), to, value);
	}
	
	function burn(uint256 value) public whenUnPaused {
		
		if(value == 0){
			revert Verifier__NoTokenBurned();
		}
		
		if(s_balance[msg.sender] < value){
			revert Verifier__InsufficientBalance();
		}
		
		s_balance[msg.sender] -= value;
		s_totalSupply -= value;
		
		if(s_balance[msg.sender] == 0){
			s_isHolder[msg.sender] = false;
		}
		else{
			s_isHolder[msg.sender] = true;
		}
		
		emit TokenBurn(msg.sender, value);
		emit Transfer(msg.sender, address(0), value);
	}
	
	
	function burnFrom(address account, uint256 value) public whenUnPaused {
		
		if(value == 0){
			revert Verifier__NoTokenBurned();
		}
		
		if(account == address(0)){
			revert Verifier__InvalidAddress();
		}
		
		if (s_balance[account] < value){
			revert Verifier__InsufficientBalance();
		}
		
		if(s_allowance[account][msg.sender] < value){
			revert Verifier__AllowanceExceeded();
		}
		
		s_allowance[account][msg.sender] -= value;
		s_balance[account] -= value;
		s_totalSupply -= value;
		
		if(s_balance[account] == 0){
			s_isHolder[account] = false;
		}
		
		emit TokenBurn(account, value);
		emit Transfer(account, address(0), value);
	 }
	
	
	function increaseAllowance(address spender, uint256 addedValue) 
        external 
         whenUnPaused returns (bool){
			
		if(spender == address(0)){
			revert Verifier__InvalidAddress();
		}
			
			uint256 newValue = s_allowance[msg.sender][spender] += addedValue;
			
			emit Approval(msg.sender, spender, newValue);
			
				return true;
		}
		
		
	function decreaseAllowance(address spender, uint256 subtractedValue) 
        external 
        whenUnPaused returns  (bool){
			
			if(spender == address(0)){
				revert Verifier__InvalidAddress();
			}
			
			if(s_allowance[msg.sender][spender] < subtractedValue){
				revert Verifier__AllowanceExceeded();
			}
			
			uint256 newValue = s_allowance[msg.sender][spender] -= subtractedValue;
			
			emit Approval(msg.sender, spender, newValue);
			
				return true;
		}
		
		function pause() public ownerOnly {
			if (s_pause == true){
				revert Verifier__IsPaused();
			}
			s_pause = true;
			
			emit Paused(msg.sender);
		}
		
		function unpause() public ownerOnly{
			if (s_pause != true){
				revert Verifier__IsUnpaused();
			}
			s_pause = false;
			
			emit Unpaused (msg.sender);
		}
		
		
		/* Getter Functions */
		
	function getListOfHolders(address holder) external view returns(bool){
		return s_isHolder[holder];
	}
	
	function getOwner() external view returns(address){
		return i_owner;
	}
}
