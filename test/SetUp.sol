// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
  ERC20Interface, ERC721Interface, ERC1155Interface
} from 'seaport-types/src/interfaces/AbridgedTokenInterfaces.sol';

import {
  AdvancedOrder,
  BasicOrderParameters,
  CriteriaResolver,
  Execution,
  Fulfillment,
  FulfillmentComponent,
  OrderParameters
} from 'seaport-sol/src/SeaportStructs.sol';

import {AdvancedOrderLib, BasicOrderParametersLib, MatchComponent} from 'seaport-sol/src/SeaportSol.sol';

import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';

import {ContractOffererInterface} from 'seaport-types/src/interfaces/ContractOffererInterface.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

import {BaseTest} from 'seaport-sol/test/BaseTest.sol';
import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';
import {ODNFVZoneControllerInterface} from '../src/interfaces/ODNFVZoneControllerInterface.sol';
import {ODNFVZoneController} from '../src/contracts/ODNFVZoneController.sol';
import {Seaport as CoreSeaport} from 'seaport-core/src/Seaport.sol';

import 'forge-std/console2.sol';

/// order builder

import {
  OrderParameters,
  OrderComponents,
  Order,
  BasicOrderParameters,
  SpentItem,
  AdditionalRecipient,
  OfferItem,
  ItemType,
  ConsiderationItem,
  Fulfillment,
  FulfillmentComponent,
  AdvancedOrder
} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {OrderType, BasicOrderType} from 'seaport-types/src/lib/ConsiderationEnums.sol';

import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';
import {BaseOrderTest} from 'seaport/test/foundry/utils/BaseOrderTest.sol';
contract SetUp is BaseOrderTest {
  using BasicOrderParametersLib for BasicOrderParameters;
  using AdvancedOrderLib for AdvancedOrder;
  using AdvancedOrderLib for AdvancedOrder[];

  address public deployer = address(0xdeadce11);
  address payable public seaportMainnetAddress = payable(address(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC)); //seaport 1.5 on arb mainnet
  CoreSeaport public seaport;
  ODNFVZoneInterface public ODNFVzone;
  ODNFVZoneController public zoneController;

  function setUp() public virtual override {
    super.setUp();
    //create arb mainnet fork;
    vm.deal(deployer, 1000 ether);
    vm.startPrank(deployer);
    seaport = CoreSeaport(seaportMainnetAddress);
    zoneController = new ODNFVZoneController(deployer);
    ODNFVzone = ODNFVZoneInterface(zoneController.createZone(keccak256(abi.encode('salt'))));
  }

}