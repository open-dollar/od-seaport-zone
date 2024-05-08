// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ODNFVZone} from './ODNFVZone.sol';

import {ODNFVZoneControllerEventsAndErrors} from '../interfaces/ODNFVZoneControllerEventsAndErrors.sol';

import {ODNFVZoneEventsAndErrors} from '../interfaces/ODNFVZoneEventsAndErrors.sol';

import {
  AdvancedOrder,
  CriteriaResolver,
  Execution,
  Fulfillment,
  Order,
  OrderComponents
} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {SeaportInterface} from 'seaport-types/src/interfaces/SeaportInterface.sol';

/**
 * @title  ODNFVZoneController
 * @author MrDeadCe11, cupOJoseph, BCLeFevre, stuckinaboot, stephankmin,
 * @notice ODNFVZoneController enables deploying, pausing and executing
 *         orders on ODNFVZones. This deployer is designed to be owned
 *         by a gnosis safe, DAO, or trusted party.
 */
contract ODNFVZoneController is ODNFVZoneControllerEventsAndErrors {
  // Set the owner that can deploy, pause and execute orders on ODNFVZones.
  address internal _owner;

  // Set the address of the new potential owner of the zone.
  address private _potentialOwner;

  // Set the address with the ability to pause the zone.
  address internal _pauser;

  // Set the immutable zone creation code hash.
  bytes32 public immutable zoneCreationCode;

  /**
   * @dev Throws if called by any account other than the owner or pauser.
   */
  modifier isPauser() {
    if (msg.sender != _pauser && msg.sender != _owner) {
      revert InvalidPauser();
    }
    _;
  }

  /**
   * @notice Set the owner of the controller and store
   *         the zone creation code.
   *
   * @param ownerAddress The deployer to be set as the owner.
   */
  constructor(address ownerAddress) {
    // Set the owner address as the owner.
    _owner = ownerAddress;

    // Hash and store the zone creation code.
    zoneCreationCode = keccak256(type(ODNFVZone).creationCode);
  }

  /**
   * @notice Deploy a ODNFVZone to a precomputed address.
   *
   * @param salt The salt to be used to derive the zone address
   *
   * @return derivedAddress The derived address for the zone.
   */
  function createZone(bytes32 salt) external returns (address derivedAddress) {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }

    // Derive the ODNFVZone address.
    // This expression demonstrates address computation but is not required.
    derivedAddress =
      address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, zoneCreationCode)))));

    // Revert if a zone is already deployed to the derived address.
    if (derivedAddress.code.length != 0) {
      revert ZoneAlreadyExists(derivedAddress);
    }

    // Deploy the zone using the supplied salt.
    new ODNFVZone{salt: salt}();

    // Emit an event signifying that the zone was created.
    emit ZoneCreated(derivedAddress, salt);
  }

  /**
   * @notice Cancel Seaport orders on a given zone.
   *
   * @param odNFVZoneAddress The zone that manages the
   * orders to be cancelled.
   * @param seaportAddress      The Seaport address.
   * @param orders              The orders to cancel.
   */
  function cancelOrders(
    address odNFVZoneAddress,
    SeaportInterface seaportAddress,
    OrderComponents[] calldata orders
  ) external {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }

    // Create a zone object from the zone address.
    ODNFVZone zone = ODNFVZone(odNFVZoneAddress);

    // Call cancelOrders on the given zone.
    zone.cancelOrders(seaportAddress, orders);
  }

  /**
   * @notice Execute an arbitrary number of matched orders on a given zone.
   *
   * @param odNFVZoneAddress The zone that manages the orders
   * to be cancelled.
   * @param seaportAddress      The Seaport address.
   * @param orders              The orders to match.
   * @param fulfillments        An array of elements allocating offer
   *                            components to consideration components.
   *
   * @return executions An array of elements indicating the sequence of
   *                    transfers performed as part of matching the given
   *                    orders.
   */
  function executeMatchOrders(
    address odNFVZoneAddress,
    SeaportInterface seaportAddress,
    Order[] calldata orders,
    Fulfillment[] calldata fulfillments
  ) external payable returns (Execution[] memory executions) {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }

    // Create a zone object from the zone address.
    ODNFVZone zone = ODNFVZone(odNFVZoneAddress);

    // Call executeMatchOrders on the given zone and return the sequence
    // of transfers performed as part of matching the given orders.
    executions = zone.executeMatchOrders{value: msg.value}(seaportAddress, orders, fulfillments);
  }

  /**
   * @notice Execute an arbitrary number of matched advanced orders on a given
   *         zone.
   *
   * @param odNFVZoneAddress The zone that manages the orders to be
   *                            cancelled.
   * @param seaportAddress      The Seaport address.
   * @param orders              The orders to match.
   * @param criteriaResolvers   An array where each element contains a
   *                            reference to a specific order as well as that
   *                            order's offer or consideration, a token
   *                            identifier, and a proof that the supplied
   *                            token identifier is contained in the
   *                            order's merkle root.
   * @param fulfillments        An array of elements allocating offer
   *                            components to consideration components.
   *
   * @return executions An array of elements indicating the sequence of
   *                    transfers performed as part of matching the given
   *                    orders.
   */
  function executeMatchAdvancedOrders(
    address odNFVZoneAddress,
    SeaportInterface seaportAddress,
    AdvancedOrder[] calldata orders,
    CriteriaResolver[] calldata criteriaResolvers,
    Fulfillment[] calldata fulfillments
  ) external payable returns (Execution[] memory executions) {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }

    // Create a zone object from the zone address.
    ODNFVZone zone = ODNFVZone(odNFVZoneAddress);

    // Call executeMatchOrders on the given zone and return the sequence
    // of transfers performed as part of matching the given orders.
    executions =
      zone.executeMatchAdvancedOrders{value: msg.value}(seaportAddress, orders, criteriaResolvers, fulfillments);
  }

  /**
   * @notice Pause orders on a given zone.
   *
   * @param zone The address of the zone to be paused.
   *
   * @return success A boolean indicating the zone has been paused.
   */
  function pause(address zone) external isPauser returns (bool success) {
    // Call pause on the given zone.
    ODNFVZone(zone).pause();

    // Return a boolean indicating the pause was successful.
    success = true;
  }

  function unpause(address zone) external isPauser returns (bool success) {
    ODNFVZone(zone).unpause();
    // Return a boolean indicating the pause was successful.
    success = true;
  }

  /**
   * @notice Initiate Zone ownership transfer by assigning a new potential
   *         owner of this contract. Once set, the new potential owner
   *         may call `acceptOwnership` to claim ownership.
   *         Only the owner in question may call this function.
   *
   * @param newPotentialOwner The address for which to initiate ownership
   *                          transfer to.
   */
  function transferOwnership(address newPotentialOwner) external {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }
    // Ensure the new potential owner is not an invalid address.
    if (newPotentialOwner == address(0)) {
      revert OwnerCanNotBeSetAsZero();
    }

    // Emit an event indicating that the potential owner has been updated.
    emit PotentialOwnerUpdated(newPotentialOwner);

    // Set the new potential owner as the potential owner.
    _potentialOwner = newPotentialOwner;
  }

  /**
   * @notice Clear the currently set potential owner, if any.
   *         Only the owner of this contract may call this function.
   */
  function cancelOwnershipTransfer() external {
    // Ensure the caller is the current owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }

    // Emit an event indicating that the potential owner has been cleared.
    emit PotentialOwnerUpdated(address(0));

    // Clear the current new potential owner.
    delete _potentialOwner;
  }

  /**
   * @notice Accept ownership of this contract. Only the account that the
   *         current owner has set as the new potential owner may call this
   *         function.
   */
  function acceptOwnership() external {
    // Ensure the caller is the potential owner.
    if (msg.sender != _potentialOwner) {
      revert CallerIsNotPotentialOwner();
    }

    // Emit an event indicating that the potential owner has been cleared.
    emit PotentialOwnerUpdated(address(0));

    // Clear the current new potential owner
    delete _potentialOwner;

    // Emit an event indicating ownership has been transferred.
    emit OwnershipTransferred(_owner, msg.sender);

    // Set the caller as the owner of this contract.
    _owner = msg.sender;
  }

  /**
   * @notice Assign the given address with the ability to pause the zone.
   *
   * @param pauserToAssign The address to assign the pauser role.
   */
  function assignPauser(address pauserToAssign) external {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }
    // Ensure the pauser to assign is not an invalid address.
    if (pauserToAssign == address(0)) {
      revert PauserCanNotBeSetAsZero();
    }

    // Set the given account as the pauser.
    _pauser = pauserToAssign;

    // Emit an event indicating the pauser has been assigned.
    emit PauserUpdated(pauserToAssign);
  }

  /**
   * @notice Assign the given address with the ability to operate the
   *         given zone.
   *
   * @param _odNFVZoneAddress The zone address to assign operator role.
   * @param operatorToAssign    The address to assign as operator.
   */
  function assignOperator(address _odNFVZoneAddress, address operatorToAssign) external {
    // Ensure the caller is the owner.
    if (msg.sender != _owner) {
      revert CallerIsNotOwner();
    }
    // Create a zone object from the zone address.
    ODNFVZone zone = ODNFVZone(_odNFVZoneAddress);

    // Call assignOperator on the zone by passing in the given
    // operator address.
    zone.assignOperator(operatorToAssign);
  }

  /**
   * @notice An external view function that returns the owner.
   *
   * @return The address of the owner.
   */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
   * @notice An external view function that returns the potential owner.
   *
   * @return The address of the potential owner.
   */
  function potentialOwner() external view returns (address) {
    return _potentialOwner;
  }

  /**
   * @notice An external view function that returns the pauser.
   *
   * @return The address of the pauser.
   */
  function pauser() external view returns (address) {
    return _pauser;
  }
}
