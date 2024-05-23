// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    Fulfillment,
    FulfillmentComponent,
    ItemType,
    OfferItem,
    Order,
    OrderComponents,
    OrderType
} from "seaport-types/src/lib/ConsiderationStructs.sol";

import { UnavailableReason } from "seaport-sol/src/SpaceEnums.sol";

import {
    ConsiderationInterface
} from "seaport-types/src/interfaces/ConsiderationInterface.sol";

import {
    ConsiderationItemLib,
    FulfillmentComponentLib,
    FulfillmentLib,
    OfferItemLib,
    OrderComponentsLib,
    OrderLib,
    SeaportArrays
} from "seaport-sol/src/lib/SeaportStructLib.sol";

import {
    TestTransferValidationZoneOfferer
} from "seaport/contracts/test/TestTransferValidationZoneOfferer.sol";

import {
    FulfillAvailableHelper
} from "seaport-sol/src/fulfillments/available/FulfillAvailableHelper.sol";

import {
    MatchFulfillmentHelper
} from "seaport-sol/src/fulfillments/match/MatchFulfillmentHelper.sol";

import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';
import {SetUp} from './SetUp.sol';
import 'forge-std/console2.sol';

contract ODNFVZoneTest is SetUp {
    using FulfillmentLib for Fulfillment;
    using FulfillmentComponentLib for FulfillmentComponent;
    using FulfillmentComponentLib for FulfillmentComponent[];
    using OfferItemLib for OfferItem;
    using OfferItemLib for OfferItem[];
    using ConsiderationItemLib for ConsiderationItem;
    using ConsiderationItemLib for ConsiderationItem[];
    using OrderComponentsLib for OrderComponents;
    using OrderLib for Order;
    using OrderLib for Order[];

    MatchFulfillmentHelper matchFulfillmentHelper;
    FulfillAvailableHelper fulfillAvailableFulfillmentHelper;
    ODNFVZone zone;

    function setUp()public virtual override {
      super.setUp();
       
    }

   
}
