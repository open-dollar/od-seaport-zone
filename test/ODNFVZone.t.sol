// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
  ERC20Interface, ERC721Interface, ERC1155Interface
} from 'seaport-types/src/interfaces/AbridgedTokenInterfaces.sol';

import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import {ReceivedItem, Schema, SpentItem, ZoneParameters} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {ItemType, OrderType, Side} from 'seaport-sol/src/SeaportEnums.sol';

import {ContractOffererInterface} from 'seaport-types/src/interfaces/ContractOffererInterface.sol';

import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

import {Test} from 'forge-std/Test.sol';
import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';
import {SetUp} from './SetUp.sol';
import 'forge-std/console2.sol';

contract ODNFVZoneTest is SetUp {
  function testFork() public {
    (string memory version, bytes32 domainSeparator, address conduitController) = seaport.information();
    console2.log(conduitController);
  }
}
