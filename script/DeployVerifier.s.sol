// SPDX=License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Verifier} from "../src/Verifier.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployVerifier is Script{

	function deploy() public returns(Verifier){
		
		vm.startBroadcast();
			Verifier verifier = new Verifier();
		vm.stopBroadcast();
		
				return verifier;
	}

	function run() external returns(Verifier){
		HelperConfig helperConfig = new HelperConfig();
		( ,
		uint256 deployerKey
		) = helperConfig.activeNetworkConfig();
		
		vm.startBroadcast(deployerKey);
		Verifier verifier = new Verifier();
		vm.stopBroadcast();
		
			return verifier;
		
	}

}