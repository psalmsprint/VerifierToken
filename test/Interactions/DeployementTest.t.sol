// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployVerifier} from "../../script/DeployVerifier.s.sol";
import {Verifier} from "../../src/Verifier.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DeployVerifierTest is Test {
	
	DeployVerifier deployer;
	Verifier verifier;
	HelperConfig helper;
	
	function setUp() public {
		
		deployer = new DeployVerifier();
		verifier = new Verifier();
		helper = new HelperConfig();
		
	}
	
	function testRunWorksWithoutCrashing() public {
		
		deployer.run();
		
	}
	
	function testDeployWorksWithoutCrashing() public {
		deployer.deploy();
	}
	
	function testRunIsConsistent() public {
		
		uint256 expectedSupply = 100_000_000 * 1e18;
		
		deployer = new DeployVerifier();
		verifier = deployer.run();
		
		assert(address(verifier) != address(0));
		assertEq(verifier.name(), "Verifier");
		assertEq(verifier.symbol(), "VRC");
		assertEq(verifier.totalSupply(), expectedSupply);
		assertEq(verifier.decimals(), 18);
		
		( , uint256 deployerKey) = new HelperConfig().activeNetworkConfig();
		  
		  address expectedOwner = vm.addr(deployerKey);
		
		assert(verifier.getOwner() == expectedOwner);
		
	}
	
	function testDeployIsConsistent() public {
		
		uint256 expectedSupply = 100_000_000 * 1e18;
		
		deployer = new DeployVerifier();
		verifier = deployer.deploy();
		
		assert(address(verifier) != address(0));
		assertEq(verifier.name(), "Verifier");
		assertEq(verifier.symbol(), "VRC");
		assertEq(verifier.totalSupply(), expectedSupply);
		assertEq(verifier.decimals(), 18);
		assertEq(verifier.getOwner(), msg.sender);
		
	}
	
}