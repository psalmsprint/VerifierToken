// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
	
	uint256 anvilKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
	
	struct NetworkConfig{
		uint256 blockConfirmation;
		uint256 deployerKey;
	}
	
	NetworkConfig public activeNetworkConfig;
	
	constructor(){
		if(block.chainid == 11155111){
			activeNetworkConfig = getSepoliaConfig();
		}
		else if(block.chainid == 1){
			activeNetworkConfig = getMainnetConfig();
		}
		else{ activeNetworkConfig = getAnvilConfig(); }
	}
	
	function getSepoliaConfig() public view returns(NetworkConfig memory){
		NetworkConfig memory sepoliConfig = NetworkConfig({
			blockConfirmation: 2,
			deployerKey: vm.envUint("PRIVATE_KEY")
		});
		
				return sepoliConfig;
	}
	
	function getMainnetConfig() public view returns(NetworkConfig memory){
		NetworkConfig memory mainnetConfig = NetworkConfig({
			blockConfirmation: 4,
			deployerKey: vm.envUint("PRIVATE_KEY")
		});
		
			return mainnetConfig;
	}
	
	function getAnvilConfig() public view returns(NetworkConfig memory){
		NetworkConfig memory anvilConfig = NetworkConfig({
			blockConfirmation: 1,
			deployerKey: anvilKey
		});
		
			return anvilConfig;
	}
}