// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ODNFVZoneControllerEventsAndErrors {
  /**
   * @dev Emit an event whenever a zone owner registers a new potential
   *      owner for that zone.
   *
   * @param newPotentialOwner The new potential owner of the zone.
   */
  event PotentialOwnerUpdated(address newPotentialOwner);

  /**
   * @dev Emit an event whenever zone ownership is transferred.
   *
   * @param previousOwner The previous owner of the zone.
   * @param newOwner      The new owner of the zone.
   */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
   * @dev Emit an event whenever a new zone is created.
   *
   * @param zone The address of the zone.
   * @param salt The salt used to deploy the zone.
   */
  event ZoneCreated(address zone, bytes32 salt);

  /**
   * @dev Emit an event whenever a zone owner assigns a new pauser
   *
   * @param newPauser The new pauser of the zone.
   */
  event PauserUpdated(address newPauser);

  /**
   * @dev Revert with an error when attempting to pause the zone
   *      while the caller is not the owner or pauser of the zone.
   */
  error InvalidPauser();
  /**
   * @dev Revert with an error when attempting to deploy a zone that is
   *      currently deployed.
   */
  error ZoneAlreadyExists(address zone);

  /**
   * @dev Revert with an error when the caller does not have the _owner role
   *
   */
  error CallerIsNotOwner();

  /**
   * @dev Revert with an error when the caller does not have the operator role
   *
   */
  error CallerIsNotOperator();

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
   * @dev Revert with an error when the caller does not have
   *      the potentialOwner role.
   */
  error CallerIsNotPotentialOwner();
}
