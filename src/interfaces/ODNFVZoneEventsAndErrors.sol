// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TraitComparison} from './Structs.sol';

interface ODNFVZoneEventsAndErrors {
  ///////////////////////// Trait Comparison///////////////////////////
  event TraitsVerified(TraitComparison traitComparison);

  error InvalidZoneHash(bytes32 zoneHash, bytes32 keccak256ExtraData);
  // error InvalidExtraData(bytes extraData);
  error UnsupportedSubstandard(uint256 substandardVersion);
  error InvalidDynamicTraitValue(
    address token,
    uint256 id,
    uint256 comparisonEnum,
    bytes32 traitKey,
    bytes32 expectedTraitValue,
    bytes32 actualTraitValue
  );
  error InvalidComparisonEnum(uint256 comparisonEnum);

  /////////////////////// Pausable ///////////////////
  /**
   * @dev Emit an event whenever a zone is successfully paused.
   */
  event Paused();

  /**
   * @dev Emit an event whenever a zone is successfully unpaused (created).
   */
  event Unpaused();

  /**
   * @dev Revert with an error when attempting to call an operation
   *      while the caller is not the controller or operator of the zone.
   */
  error InvalidOperator();

  /**
   * @dev Revert with an error when attempting to pause the zone or update the
   *      operator while the caller is not the controller of the zone.
   */
  error InvalidController();

  /**
   * @dev Revert with an error when the zone is paused
   */
  error ZoneIsPaused();

  /**
   * @dev Revert with an error when attempting to set the new potential owner
   *      as the 0 address.
   *
   */
  error OwnerCanNotBeSetAsZero();

  /**
   * @dev Revert with an error when attempting to set the new potential pauser
   *      as the 0 address.
   *
   */
  error PauserCanNotBeSetAsZero();

  /**
   * @dev Emit an event whenever a zone owner assigns a new operator
   *
   * @param newOperator The new operator of the zone.
   */
  event OperatorUpdated(address newOperator);
}
