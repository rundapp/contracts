// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/contracts/RunChallenger.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        RunChallenger runChallenger = new RunChallenger(0x1371142197EC6CAAE57489471935927778f26C5E);
        vm.stopBroadcast();
    }
}

// ##### USAGE #####
// ##### To load the variables in the .env file: ####

// source .env

// ##### To deploy and verify our contract: ####

// ##### DEPLOYMENTS TO POLYGON #####
// forge script script/RunChallenger.s.sol:DeployScript --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify

// ##### DEPLOYMENTS TO ETHEREUM (WITH ETHERSCAN) #####
// forge script script/RunChallenger.s.sol:DeployScript --rpc-url $RINKEBY_RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv

