// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {
  ERC20Interface, ERC721Interface, ERC1155Interface
} from 'seaport-types/src/interfaces/AbridgedTokenInterfaces.sol';

import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import {ReceivedItem, Schema, SpentItem, ZoneParameters} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';

import {ContractOffererInterface} from 'seaport-types/src/interfaces/ContractOffererInterface.sol';

import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

import {Test} from 'forge-std/Test.sol';
import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';

import {Seaport as CoreSeaport} from 'seaport-core/src/Seaport.sol';
import 'forge-std/console2.sol';

contract SetUp is Test {
  address payable public seaportMainnetAddress = payable(address(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC)); //seaport 1.5 on arb mainnet
  CoreSeaport public seaport = CoreSeaport(seaportMainnetAddress);

  function setUp() public {
    //create arb mainnet fork;
    vm.createSelectFork(vm.envString('[ARB_MAINNET_RPC'));
  }
}
