// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

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

import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';
import {ODNFVZoneControllerInterface} from '../src/interfaces/ODNFVZoneControllerInterface.sol';
import {ODNFVZoneController} from '../src/contracts/ODNFVZoneController.sol';
import {Seaport as CoreSeaport} from 'seaport-core/src/Seaport.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';
import {IVault721Adapter} from '../src/interfaces/IVault721Adapter.sol';
// import {Vault721Adapter} from '../src/contracts/Vault721Adapter.sol';
import {IVault721} from '../src/interfaces/IVault721.sol';
import {BaseOrderTest} from 'seaport/test/foundry/utils/BaseOrderTest.sol';
import 'forge-std/console2.sol';
import 'forge-std/Test.sol';



contract SetUp is BaseOrderTest {
  using BasicOrderParametersLib for BasicOrderParameters;
  using AdvancedOrderLib for AdvancedOrder;
  using AdvancedOrderLib for AdvancedOrder[];

  address public deployer = address(0xdeadce11);
  address public vault721AdapterAddress = address(0x0005AFE00fF7E7FF83667bFe4F2996720BAf0B36);
  IVault721Adapter public vault721Adapter;
  IVault721 public vault721;
  address payable public seaportMainnetAddress = payable(address(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC)); //seaport 1.5 on arb mainnet
  CoreSeaport public seaport;
  ODNFVZoneInterface public ODNFVzone;
  ODNFVZoneController public zoneController;

  function setUp() public virtual override  {
    super.setUp();
    //create arb mainnet fork;
    vm.deal(deployer, 1000 ether);
    vm.startPrank(deployer);
    seaport = CoreSeaport(seaportMainnetAddress);
    zoneController = new ODNFVZoneController(deployer);
    ODNFVzone = ODNFVZoneInterface(zoneController.createZone(keccak256(abi.encode('salt'))));
    vault721 = IVault721(vault721AdapterAddress);
    vault721Adapter = IVault721Adapter(address(vault721));
  }

}
