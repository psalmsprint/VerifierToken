// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import  "../../src/Verifier.sol";
import {Test} from "forge-std/Test.sol";
import {DeployVerifier} from "../../script/DeployVerifier.s.sol";

contract VerifierTest is Test{

	DeployVerifier deployer;
	Verifier verifier;
	
	address bob = makeAddr("bob");
	address sandra = makeAddr("sandra");
	
	uint256 private constant STARTING_USE_BALANCE = 20 ether;
	uint256 private constant TRANSFER_AMOUNT = 1 ether;
	
	
				/* Events */
	event Transfer(address indexed sender, address indexed receiver, uint256 amount);
	event Approval(address indexed sender, address indexed receiver, uint256 amount);
	event TokenMint(address indexed sender, address indexed receiver, uint256 amount);
	event TokenBurn(address indexed sender, uint256 amount);
	event Paused(address indexed sender);
	event Unpaused(address indexed sender);
	
	
	function setUp() public {
		deployer = new DeployVerifier();
		
		verifier = deployer.deploy();

	}
	
	
	function testVerifierNmae() public view{
		assertEq(verifier.name(), "Verifier");
	}
	
	function testVerifierSymbol() public view {
		assertEq(verifier.symbol(), "VRC");
	}
	
	function testVerfifierdecimals() public view {
		assertEq(verifier.decimals(), 18);
	}
	
	function testTotalSupply() public view {
		
		uint256 supply = verifier.totalSupply();
		
		uint256 expectedSupply = 100_000_000*1e18; 
		
		assert(supply == expectedSupply);
	}
	
	function testBalanceOfHolders() public mintedToken{

		assertEq (verifier.balanceOf(sandra), STARTING_USE_BALANCE); 
	}
	
	
	modifier mintedToken(){
		vm.startPrank(msg.sender);
		verifier.mint(bob, STARTING_USE_BALANCE);
		verifier.mint(sandra, STARTING_USE_BALANCE);
		vm.stopPrank();
		_;
	}
	
					///////////////////////
					/////  Transfer //////
					/////////////////////
		
	function testTransferDidNotSendToAddressZero() public mintedToken{
		
		vm.prank(bob);
		vm.expectRevert(Verifier__InvalidAddress.selector);
		verifier.transfer(address(0), TRANSFER_AMOUNT);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
	}
	
	function testRevertIfTransferValueIsLessThanUserBalance() public mintedToken{
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__InsufficientBalance.selector);
		verifier.transfer(bob, 30 ether);
		
		assertEq(verifier.balanceOf(sandra), STARTING_USE_BALANCE);
	}
	
	function testVerifierDeductFromSenderBalanceAndAddToRecieverBalance() public mintedToken{
		
		uint256 balanceOfBob = verifier.balanceOf(bob);
		
		vm.prank(bob);
		verifier.transfer(sandra, TRANSFER_AMOUNT);
		
		uint256 expectedBalanceOfBob = verifier.balanceOf(bob);
		
		assertEq(balanceOfBob - TRANSFER_AMOUNT , expectedBalanceOfBob);
		assertEq(verifier.balanceOf(sandra), STARTING_USE_BALANCE + TRANSFER_AMOUNT);
	}
	
	function testVerifierAddRecieverToTheListOfHolders() public mintedToken{
		address john = makeAddr("john");
		
		vm.prank(bob);
		verifier.transfer(john, TRANSFER_AMOUNT);
		
		assert(verifier.getListOfHolders(john) == true);
	}
	
	function testVerifierRemovedFromHoldersListIfTransferAllToken() public mintedToken{
		vm.prank(sandra);
		verifier.transfer(bob, STARTING_USE_BALANCE);
		
		assert(verifier.getListOfHolders(sandra) == false);
	}
	
	function testVerifierTransferEmitEvent() public mintedToken{
		
		vm.expectEmit(true, true, false, false);
		emit Transfer(bob, sandra, TRANSFER_AMOUNT);
		
		vm.prank(bob);
		verifier.transfer(sandra, TRANSFER_AMOUNT);
	}
	
	
	function testMultipleHoldersTransfer() public mintedToken{
		
		uint256 amount = 0.2 ether;
		
		uint256 indexOfSpender = 40;
		
		for (uint256 i = 0; i < indexOfSpender; i++){
			
			address Spenders = makeAddr(string(abi.encodePacked("Spenders", i)));
			
			uint256 expectedBalance = verifier.balanceOf(sandra);
			
			vm.expectEmit(true, true, false, false);
			emit Transfer(sandra, Spenders, amount);
			
			vm.prank(sandra);
			verifier.transfer(Spenders, amount);
			
			expectedBalance -= amount;
			
			assertEq(verifier.balanceOf(sandra), expectedBalance);
			assert(verifier.getListOfHolders(Spenders) == true);
			assert(verifier.balanceOf(Spenders) == amount);
		}
	}
	
	
	
				////////////////////////////
				//////  TransferFrom  /////
				//////////////////////////
	
	function testTransferFromRevertIfSentToAddrZero() public mintedToken{
		
		vm.prank(bob);
		vm.expectRevert(Verifier__InvalidAddress.selector);
		verifier.transferFrom(bob, address(0), TRANSFER_AMOUNT);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
	}
	
	function testTransferFromRevertIfAmountIsHigherThanBalance() public mintedToken{
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__InsufficientBalance.selector);
		verifier.transferFrom(sandra, bob, 21 ether);
	}
	

	function testTransferFromPassIfTransferAllBalanceAndUpdateIsHolder() public mintedToken{
		
		vm.startPrank(bob);
		verifier.approve(sandra, STARTING_USE_BALANCE);
		verifier.allowance(bob, sandra);
		vm.stopPrank();
		
		vm.startPrank(sandra);
		verifier.transferFrom(bob, sandra, STARTING_USE_BALANCE);
		
		assert(verifier.getListOfHolders(bob) == false);
		assertEq(verifier.balanceOf(bob), 0);
	}
	
	
	function testTransferFromRevertIfAllowanceIsLessThanAmount() public mintedToken{
		
		vm.prank(sandra);
		verifier.approve(bob, TRANSFER_AMOUNT);
		
		vm.prank(bob);
		vm.expectRevert(Verifier__AllowanceExceeded.selector);
		verifier.transferFrom(sandra, bob, 2 ether);
		
		assert(verifier.balanceOf(bob) == STARTING_USE_BALANCE);
	}
	
	function testVerifierUdateBalanceAndHolderIfUserTransferAndEmitEvent() public mintedToken{
		
		address cash = makeAddr("cash");
		uint256 transferAmount = 0.4 ether;
		
		vm.prank(bob);
		verifier.approve(cash, TRANSFER_AMOUNT);
		
		uint256 allowedValue = verifier.allowance(bob, cash);
		
		vm.expectEmit(true, true, false, false);
		emit Transfer(bob, cash, transferAmount);
		
		vm.prank(cash);
		verifier.transferFrom(bob, cash, transferAmount);
		
		uint256 expectedAllowance = verifier.allowance(bob, cash);
		
		assertEq(allowedValue - transferAmount, expectedAllowance);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE - transferAmount);
		assertEq(verifier.balanceOf(cash), transferAmount);
		
		assert(verifier.getListOfHolders(bob) == true);
		assert(verifier.getListOfHolders(cash) == true);
		
	}
	
	
	function testMultilpeHoldersTransferFrom() public mintedToken{
		
		uint256 value = 0.1 ether;
		
		uint256 indexOfHolders = 100;
		
		for (uint256 i = 0; i < indexOfHolders; i++){
			
			address spenders = makeAddr(string(abi.encodePacked("spenders", i)));
			
			vm.prank(bob);
			verifier.approve(spenders, TRANSFER_AMOUNT);
			
			uint256 expectedBalance = verifier.balanceOf(bob);
			
			vm.expectEmit(true, true, false, false);
			emit Transfer(bob, spenders, value);
			
			vm.prank(spenders);
			verifier.transferFrom(bob, spenders, value);
			
			expectedBalance -= value;
			
			assertEq(verifier.balanceOf(bob), expectedBalance);
			assert(verifier.getListOfHolders(spenders) == true);
			assertEq(verifier.balanceOf(spenders), value);
			
		}
	}
	
	
	
			///////////////////////
			/////// Approve //////
			/////////////////////
	
	function testApproveRevertIfApproveToAddressZero() public mintedToken{
		
		vm.prank(bob);
		vm.expectRevert(Verifier__ApproveToInvalidAddress.selector);
		verifier.approve(address(0), TRANSFER_AMOUNT);
		
	}
	
	function testApproveUpdateAllowanceAndEmitEvent() public mintedToken {
		
		vm.expectEmit(true,true,false, false);
		emit Approval(sandra, bob, TRANSFER_AMOUNT);
		
		vm.prank(sandra);
		verifier.approve(bob, TRANSFER_AMOUNT);
		
		uint256 allowedValue = verifier.allowance(sandra, bob);
		
		assert(allowedValue == TRANSFER_AMOUNT);
		
	}
	

				///////////////////
			//// Allowance ////
			//////////////////
	
	function testAllowance() public mintedToken{
		
		uint256 value = 0.2 ether;
		
		vm.prank(bob);
		verifier.approve(sandra, TRANSFER_AMOUNT);
		
		uint256 approvedBalance = verifier.allowance(bob, sandra);
		
		vm.prank(sandra);
		verifier.transferFrom(bob,sandra, value);
		
		uint256 updatedBalance = verifier.allowance(bob, sandra);
		
		assertEq(approvedBalance - value, updatedBalance);
	}
	
	
				//////////////////
				///// Mint //////
				////////////////
	
	function testVerifierRevertIfMintedToInvalidAddr() public {
		
		vm.prank(msg.sender);
		vm.expectRevert(Verifier__MintingToInvalidAddress.selector);
		verifier.mint(address(0), STARTING_USE_BALANCE);
		
	}
	
	function testVerifierRevertIfMintNoValue() public {
		
		vm.prank(msg.sender);
		vm.expectRevert(Verifier__NoTokenMinted.selector);
		verifier.mint(bob, 0);
		
		assertEq(verifier.balanceOf(bob), 0);
	}
	
	function testMintTokenToAnAddrUpateBalanceAndTotalSupplyAddReceiverToHolderAndEmitEvent() public {
		
		uint256 supply = verifier.totalSupply();
		
		vm.expectEmit(true, true, false, false);
		emit Transfer(address(0), bob, STARTING_USE_BALANCE);
		emit TokenMint(address(0), bob, STARTING_USE_BALANCE);
		
		vm.prank(msg.sender);
		verifier.mint(bob, STARTING_USE_BALANCE);
		
		uint256 newSupply = verifier.totalSupply();
		
		assertEq(supply + STARTING_USE_BALANCE, newSupply);
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
		assert(verifier.getListOfHolders(bob) == true);
		
	}
	
	function testMintToMultipleAddrAndUpdateBalanceAddToHolder() public {
		
		uint256 supply = verifier.totalSupply();
		
		uint256 indexOfAddr = 100;
		
		for (uint256 i = 0; i < indexOfAddr; i++){
			
			address receivers = makeAddr(string(abi.encodePacked("receivers", i)));
			
			
			vm.expectEmit(true, true, false, false);
			emit Transfer(address(0), receivers, STARTING_USE_BALANCE);
			
			vm.prank(msg.sender);
			verifier.mint(receivers, STARTING_USE_BALANCE);
			
			supply += STARTING_USE_BALANCE; 
			
			assertEq(verifier.balanceOf(receivers), STARTING_USE_BALANCE);
			assert(verifier.getListOfHolders(receivers) == true);
			assertEq(verifier.totalSupply(), supply);
		}
	}
	
		////////////
		/// Burn ///
		///////////
		
	function testRevertWhenBurnZerToken() public mintedToken{
		
		vm.prank(bob);
		vm.expectRevert(Verifier__NoTokenBurned.selector);
		verifier.burn(0);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
	}
	
	function testBurnRevertWhenBalanceIsLessThanValue() public {
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__InsufficientBalance.selector);
		verifier.burn(TRANSFER_AMOUNT);

	}
	
	function testBurnUpdateBalaceAndListOfHoldersWhenBurnAllToken() public mintedToken{
		
		vm.prank(bob);
		verifier.burn(STARTING_USE_BALANCE);
		
		assertEq(verifier.balanceOf(bob), 0);
		assert(verifier.getListOfHolders(bob) == false);
	}
	
	function testBurnPassedUpdateSupplyBalanceListOfHoldersAndEmitEvent() public mintedToken{
		
		uint256 supply = verifier.totalSupply();
		
		vm.expectEmit(true, true, false, false);
		emit TokenBurn(sandra, TRANSFER_AMOUNT);
		emit Transfer(sandra, address(0), TRANSFER_AMOUNT);
		
		vm.prank(sandra);
		verifier.burn(TRANSFER_AMOUNT);
		
		uint256 expectedSupply = verifier.totalSupply();
		
		assertEq(verifier.balanceOf(sandra), STARTING_USE_BALANCE - TRANSFER_AMOUNT);
		assertEq(supply - TRANSFER_AMOUNT, expectedSupply);
		assert(verifier.getListOfHolders(sandra) == true);
		
	}
	
	function testMultipleUsersBurnAndTheirDataIsUpdated() public {
		
		uint256 indexOfAddr = 50;
		
		for (uint256 i = 0; i < indexOfAddr; i++){
			
			address burners = makeAddr(string(abi.encodePacked("burners", i)));
			
			vm.prank(msg.sender);
			verifier.mint(burners, STARTING_USE_BALANCE);
			
			uint256 supply = verifier.totalSupply();
			
			vm.expectEmit(true, true, false, false);
			emit TokenBurn (burners, TRANSFER_AMOUNT);
			
			vm.prank(burners);
			verifier.burn(TRANSFER_AMOUNT);
			
			supply -= TRANSFER_AMOUNT;
			
			assertEq(verifier.balanceOf(burners), STARTING_USE_BALANCE - TRANSFER_AMOUNT);
			assert(verifier.getListOfHolders(burners) != false);
			assertEq(verifier.totalSupply(), supply);
			
		}
		
	}
	
	         ///////////////////////
			 ///// BurnFrom ///////
			//////////////////////
			
	function testBurnFromRevetIfZreoAmountIsBurn() public mintedToken {
		
		vm.prank(bob);
		vm.expectRevert(Verifier__NoTokenBurned.selector);
		verifier.burnFrom(bob, 0);
	}	
	
	function testRevertWhenBurnFromZeroAddress() public {
		
		vm.prank(address(0));
		vm.expectRevert(Verifier__InvalidAddress.selector);
		verifier.burnFrom(address(0), 1 ether);
		
	}
	
	function testRevertWhenBalanceOfAccountIsLessThanAmount() public mintedToken{
		
		vm.prank(bob);
		verifier.approve(sandra, STARTING_USE_BALANCE);
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__InsufficientBalance.selector);
		verifier.burnFrom(bob, 21 ether);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
		
	}
	
	function testRevertIfAllowanceIsLessThanValue() public mintedToken{
		
		vm.prank(sandra);
		verifier.approve(bob, TRANSFER_AMOUNT);
		
		vm.prank(bob);
		vm.expectRevert(Verifier__AllowanceExceeded.selector);
		verifier.burnFrom(sandra, STARTING_USE_BALANCE);
		
		assertEq(verifier.balanceOf(sandra), STARTING_USE_BALANCE);
	}
	
	function testBurnFromPassedUpdateAllowanceBalanceHoldersTotalSupplyAndEmitEvent() public mintedToken {
		
		uint256 value = 0.5 ether;
		uint256 supply = verifier.totalSupply();
		
		vm.prank(bob);
		verifier.approve(sandra, TRANSFER_AMOUNT);
		
		vm.expectEmit(true, true, false, false);
		emit TokenBurn(bob, value);
		emit Transfer(bob, address(0), value);
		
		vm.prank(sandra);
		verifier.burnFrom(bob, value);
		
		uint256 newSupply = verifier.totalSupply();
		
		uint256 expectedSupply = supply - value;
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE - value);
		assertEq(verifier.allowance(bob, sandra), TRANSFER_AMOUNT - value);
		assertEq(expectedSupply, newSupply);
		assert(verifier.getListOfHolders(bob) == true);
	}
	
	function testBurnFromUpdatedMultipileBurner() public mintedToken{
		
		uint256 supply = verifier.totalSupply();
		uint256 balanceOfBob = verifier.balanceOf(bob);
		
		uint256 indexOfBurners = 15;
		
		for (uint256 i = 0; i < indexOfBurners; i++){

			address burners = makeAddr(string(abi.encodePacked("burners", i)));
			
			vm.prank(bob);
			verifier.approve(burners, TRANSFER_AMOUNT);
			
			vm.expectEmit(true, true, false, false);
			emit TokenBurn(bob, TRANSFER_AMOUNT);
			emit Transfer(bob, address(0), TRANSFER_AMOUNT);
			
			vm.prank(burners);
			verifier.burnFrom(bob, TRANSFER_AMOUNT);
			
			balanceOfBob -= TRANSFER_AMOUNT;
			supply -= TRANSFER_AMOUNT;
			
			assert(verifier.allowance(bob, burners) == 0);
			assertEq(verifier.balanceOf(bob), balanceOfBob);
			assertEq(verifier.totalSupply(), supply);
			assert(verifier.getListOfHolders(burners) == false);
			
		}
	}
	
	
				/////////////////////////
				/// IncreaseAllowance ///
				////////////////////////

	function testRevertIfIncreasingToAddrZero() public mintedToken {
		
		vm.prank(bob);
		vm.expectRevert(Verifier__InvalidAddress.selector);
		verifier.increaseAllowance(address(0), TRANSFER_AMOUNT);
		
	}
	
	
	function testAllowanceIsIncreasedUpdatedAndEmitEvent() public {
		
		uint256 value = 0.1 ether;
		
		vm.prank(bob);
		verifier.approve(sandra, value);
		
		uint256 initialAllowance = verifier.allowance(bob, sandra);
		
		vm.expectEmit(true, true, false, false);
		emit Approval(bob, sandra, TRANSFER_AMOUNT);
		
		vm.prank(bob);
		verifier.increaseAllowance(sandra, TRANSFER_AMOUNT);
		
		uint256 expectedAllowance = initialAllowance + TRANSFER_AMOUNT;
		
		assertEq(expectedAllowance, verifier.allowance(bob, sandra));
	}
	
			//////////////////////////
			/// DecreaseAllowance ///
			////////////////////////
			
	function testRevertIfDecreasingFromAddrZero() public mintedToken{
		
		vm.prank(bob);
		vm.expectRevert(Verifier__InvalidAddress.selector);
		verifier.decreaseAllowance(address(0), TRANSFER_AMOUNT);
	}
	
	function testRevertIfDecreaseAllowanceIsHigherThanAllowance() public {
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__AllowanceExceeded.selector);
		verifier.decreaseAllowance(bob, TRANSFER_AMOUNT);
		
	}
	
	function testAllowanceDecreaseUpdateValueAndEmitEvent() public mintedToken{
		
		uint256 value = 0.1 ether;
		
		vm.prank(bob);
		verifier.approve(sandra, TRANSFER_AMOUNT);
		
		uint256 initialAllowance = verifier.allowance(bob, sandra);
		
		vm.expectEmit(true, true, false, false);
		emit Approval(bob, sandra, value);
		
		vm.prank(bob);
		verifier.decreaseAllowance(sandra, value);
		
		uint256 newAllowance = verifier.allowance(bob, sandra);
		
		uint256 expectedAllowance = initialAllowance - value;
		
		assertEq(newAllowance, expectedAllowance);
		
	}
	
		 ////////////
		/// pause ///
		////////////
		
	function testRevertWhenContractIsAlreadyPaused() public {
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(msg.sender);
		vm.expectRevert(Verifier__IsPaused.selector);
		verifier.pause();
	}
	
	function testPausedIsSetAndEmitEvent() public {
		
		vm.expectEmit(true, false, false, false);
		emit Paused(msg.sender);
		
		vm.prank(msg.sender);
		verifier.pause();
		
	}
	
	function testPauseRevertWhenNotOwner() public {
	
		vm.prank(bob);
		vm.expectRevert(Verifier__NotAllowed.selector);
		verifier.pause();
	}
	
	
	function testTransferRevertWhenContractIsPaused() public mintedToken{
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(bob);
		vm.expectRevert(Verifier__ContractPaused.selector);
		verifier.transfer(sandra, TRANSFER_AMOUNT);
		
	}
	
	function testMintRevertWhenContractIsPaused() public {
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(msg.sender);
		vm.expectRevert(Verifier__ContractPaused.selector);
		verifier.mint(bob, STARTING_USE_BALANCE);
	}
	
	function testTransferFronRevertWhenContractIsPaused() public mintedToken{
		
		vm.prank(bob);
		verifier.approve(sandra, TRANSFER_AMOUNT);
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__ContractPaused.selector);
		verifier.transferFrom(bob, sandra, TRANSFER_AMOUNT);
		
		assertEq(verifier.balanceOf(bob), STARTING_USE_BALANCE);
	}
	
	function testBurnRevertWhenContractIsLocked() public mintedToken{
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__ContractPaused.selector);
		verifier.burn(TRANSFER_AMOUNT);
	}
	
	function testBurnFromRevertWhenContractIsPaused() public mintedToken {
		
		vm.prank(bob);
		verifier.approve(sandra, TRANSFER_AMOUNT);
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(sandra);
		vm.expectRevert(Verifier__ContractPaused.selector);
		verifier.burnFrom(bob, TRANSFER_AMOUNT);
	}
	
				////////////////
				/// UnPaused ///
				////////////////
				
	function testUnpauseRevertWhenContractIsNotPuased() public {
		
		vm.prank(msg.sender);
		vm.expectRevert(Verifier__IsUnpaused.selector);
		verifier.unpause();
	}
	
	function testVerifierIsUnPuasedAfterItWasPausedAndEmitEvent() public {
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.expectEmit(true, false, false, false);
		emit Unpaused(msg.sender);
		
		vm.prank(msg.sender);
		verifier.unpause();
	}
	
	function testTransactionPassedWhenContractWasUnpaused() public mintedToken{
		
		vm.prank(msg.sender);
		verifier.pause();
		
		vm.prank(msg.sender);
		verifier.unpause();
		
		vm.prank(bob);
		verifier.transfer(sandra, TRANSFER_AMOUNT);
		
		uint256 expectedBalance = STARTING_USE_BALANCE - TRANSFER_AMOUNT; 
		
		assertEq(verifier.balanceOf(bob), expectedBalance);
	}
	
	
	///////////////////
	/// Constructor ///
	//////////////////
	
	function testConstructorSetBalanceOfOwnerToTotalSupply() public {
		
		assertEq(verifier.balanceOf(msg.sender), verifier.totalSupply());
		
	}
	
}