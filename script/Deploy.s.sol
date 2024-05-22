// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {Script} from 'forge-std/Script.sol';

// BROADCAST
// source .env && forge script Deploy --skip-simulation --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_MAINNET_RPC --broadcast --verify --etherscan-api-key $ARB_ETHERSCAN_API_KEY

// SIMULATE
// source .env && forge script Deploy --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_MAINNET_RPC

/**
 * @dev deploys a contract
 */
contract Deploy is Script {
  function run() public {
    vm.startBroadcast(vm.addr(vm.envUint('ARB_MAINNET_DEPLOYER_PK')));

    vm.stopBroadcast();
  }
}
