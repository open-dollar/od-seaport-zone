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

/**
 * @title  PausableZone
 * @author cupOJoseph, BCLeFevre, ryanio
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone.
 */
interface ODNFVZoneInterface {
  /**
   * @notice Pause this contract, safely stopping orders from using
   *         the contract as a zone. Restricted orders with this address as a
   *         zone will not be fulfillable unless the zone is unpaused.
   */
  function pause() external;

  /**
   * @notice UnPause this contract, safely allowing orders to use
   *         the contract as a zone. Restricted orders with this address as a
   *         zone will be fulfillable.
   */
  function unpause() external;

  /**
   * @notice Assign the given address with the ability to operate the zone.
   *
   * @param operatorToAssign The address to assign as the operator.
   */
  function assignOperator(address operatorToAssign) external;
}
