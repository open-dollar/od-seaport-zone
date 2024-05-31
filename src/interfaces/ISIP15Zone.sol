// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {SeaportInterface} from 'seaport-types/src/interfaces/SeaportInterface.sol';

import {
  AdvancedOrder,
  CriteriaResolver,
  Execution,
  Fulfillment,
  Order,
  OrderComponents
} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

/**
 * @title  ISIP15Zone
 * @author cupOJoseph, BCLeFevre, ryanio, MrDeadCe11
 */
interface ISIP15Zone is ZoneInterface {
  struct TraitComparison {
    address token;
    uint256 id;
    uint8 comparisonEnum;
    bytes32 traitValue;
    bytes32 traitKey;
  }
}
