// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';
import {SIP15Zone} from '../src/contracts/SIP15Zone.sol';
import {Vault721Adapter} from '../src/contracts/Vault721Adapter.sol';
import {IVault721} from '@opendollar/interfaces/proxies/IVault721.sol';
import {SepoliaContracts} from '@opendollar/script/SepoliaContracts.s.sol';
import {MainnetContracts} from '@opendollar/script/MainnetContracts.s.sol';

// sepolia deployment
// to use cast wallet:

// cast wallet import defaultKey --interactive

// and then:
// source .env && forge script script/DeploySIP15Zone.sol:DeploySIP15ZoneWithCastWallet --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_SEPOLIA_RPC --broadcast --verify --etherscan-api-key $ARB_ETHERSCAN_API_KEY --acount defaultKey --sender DEFAULT_KEY_PUBLIC_ADDRESS

// to use .env
// source .env && forge script script/DeploySIP15Zone.sol:DeploySIP15ZoneWithENV --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_SEPOLIA_RPC --broadcast --verify --etherscan-api-key $ARB_ETHERSCAN_API_KEY

contract DeploySIP15ZoneWithENV is Script {
  uint256 internal _privateKey;
  address public deployer;
  address public vault721;

  error UnrecognizedChainId();

  function run() public {
    _loadPrivateKeys();

    vm.startBroadcast(_privateKey);
    address zoneAddress = address(new SIP15Zone());
    address vault721Adapter = address(new Vault721Adapter(IVault721(vault721)));
    vm.stopBroadcast();
    console2.log('Zone Deployed at: ', zoneAddress);
    console2.log('vault721Adapter Deployed at: ', vault721Adapter);
  }

  function _loadPrivateKeys() internal {
    if (block.chainid == 421_614) {
      _privateKey = vm.envUint('ARB_SEPOLIA_PK');
      deployer = vm.addr(_privateKey);
      vault721 = address(0x05AC7e3ac152012B980407dEff2655c209667E4c); // SepoliaContracts.Vault721_Address;
    } else if (block.chainid == 42_161) {
      _privateKey = vm.envUint('ARB_MAINNET_PK');
      deployer = vm.addr(_privateKey);
      vault721 = address(0x0005AFE00fF7E7FF83667bFe4F2996720BAf0B36); // MainnetContracts.Vault721_Address;
    } else {
      revert UnrecognizedChainId();
    }

    console2.log('\n');
    console2.log('deployer address:', deployer);
    console2.log('deployer balance:', deployer.balance);
  }

  function _deploy() internal {
    new SIP15Zone();
  }
}


contract DeploySIP15ZoneWithCastWallet is Script {
  uint256 internal _privateKey;
  address public deployer;
  address public vault721;

  error UnrecognizedChainId();

  function run() public {
    _loadAddresseses();
    vm.startBroadcast();
    address zoneAddress = address(new SIP15Zone());
    address vault721Adapter = address(new Vault721Adapter(IVault721(vault721)));
    vm.stopBroadcast();
    console2.log('Zone Deployed at: ', zoneAddress);
    console2.log('vault721Adapter Deployed at: ', vault721Adapter);
  }

  function _loadAddresseses() internal {
    if (block.chainid == 421_614) {
      vault721 = address(0x05AC7e3ac152012B980407dEff2655c209667E4c); // SepoliaContracts.Vault721_Address;
    } else if (block.chainid == 42_161) {
      vault721 = address(0x0005AFE00fF7E7FF83667bFe4F2996720BAf0B36); // MainnetContracts.Vault721_Address;
    } else {
      revert UnrecognizedChainId();
    }
  }

  function _deploy() internal {
    new SIP15Zone();
  }
}
