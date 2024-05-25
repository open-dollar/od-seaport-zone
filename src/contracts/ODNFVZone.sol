// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC165} from '@openzeppelin/utils/introspection/ERC165.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';
import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';
import {SIP6Decoder} from 'shipyard-core/src/sips/lib/SIP6Decoder.sol';
import {ODNFVZoneEventsAndErrors} from '../interfaces/ODNFVZoneEventsAndErrors.sol';
import {TraitComparison} from '../libraries/Structs.sol';
import {ODNFVZoneInterface} from '../interfaces/ODNFVZoneInterface.sol';

/**
 * @title  ODSeaportZone
 * @author MrDeadce11 & stephankmin
 * @notice ODSeaportZone is an implementation of SIP-15. It verifies that the dynamic traits of an NFT
 *         have not changed between the time of order creation and the time of order fulfillment.
 */
contract ODNFVZone is ERC165, ZoneInterface, ODNFVZoneInterface, ODNFVZoneEventsAndErrors {
  using SIP6Decoder for bytes;

  bool public isPaused;
  address private _controller;
  // Set an operator that can instruct the zone to cancel or execute orders.
  address public operator;

  /**
   * @notice Set the deployer as the controller of the zone.
   */
  constructor() {
    // Set the controller to the deployer.
    _controller = msg.sender;

    // Emit an event signifying that the zone is unpaused.
    emit Unpaused();
  }

  /**
   * @dev Ensure that the caller is either the operator or controller.
   */
  modifier isOperator() {
    // Ensure that the caller is either the operator or the controller.
    if (msg.sender != operator && msg.sender != _controller) {
      revert InvalidOperator();
    }

    // Continue with function execution.
    _;
  }

  /**
   * @dev Ensure that the caller is the controller.
   */
  modifier isController() {
    // Ensure that the caller is the controller.
    if (msg.sender != _controller) {
      revert InvalidController();
    }

    // Continue with function execution.
    _;
  }
  /**
   * @dev Ensure that the zone is not paused.
   */

  modifier isNotPaused() {
    // Ensure that the zone is not paused.
    if (isPaused) {
      revert ZoneIsPaused();
    }

    // Continue with function execution.
    _;
  }

  /**
   * @notice Pause this contract, safely stopping orders from using
   *         the contract as a zone. Restricted orders with this address as a
   *         zone will no longer be fulfillable.
   */
  function pause() external isController {
    // Emit an event signifying that the zone is paused.
    emit Paused();

    // Pause the zone.
    isPaused = true;
  }

  /**
   * @notice Pause this contract, safely stopping orders from using
   *         the contract as a zone. Restricted orders with this address as a
   *         zone will no longer be fulfillable.
   */
  function unpause() external isController {
    // Emit an event signifying that the zone is unpaused.
    emit Unpaused();

    // Pause the zone.
    isPaused = false;
  }

  /**
   * @notice Assign the given address with the ability to operate the zone.
   *
   * @param operatorToAssign The address to assign as the operator.
   */
  function assignOperator(address operatorToAssign) external isController {
    // Ensure the operator being assigned is not the null address.
    if (operatorToAssign == address(0)) {
      revert PauserCanNotBeSetAsZero();
    }

    // Set the given address as the new operator.
    operator = operatorToAssign;

    // Emit an event indicating the operator has been updated.
    emit OperatorUpdated(operatorToAssign);
  }

  /**
   * @dev Validates an order.
   *
   * @param zoneParameters The context about the order fulfillment and any
   *                       supplied extraData.
   *
   * @return validOrderMagicValue The magic value that indicates a valid
   *                             ff order.
   */
  function validateOrder(ZoneParameters calldata zoneParameters)
    public
    view
    isNotPaused
    returns (bytes4 validOrderMagicValue)
  {
    // Get zoneHash from zoneParameters
    // note: keccak of fixed data array is going to be zoneHash
    // extraData isn't signed
    bytes32 zoneHash = zoneParameters.zoneHash;

    // Get extraData from zoneParameters
    bytes calldata extraData = zoneParameters.extraData;

    // Validate that the zoneHash matches the keccak256 hash of the extraData
    if (zoneHash != keccak256(extraData)) {
      revert InvalidZoneHash(zoneHash, keccak256(extraData));
    }

    // TODO: ask if this should be SIP-6 or SIP-15
    // Decode substandard version from extraData using SIP-6 decoder
    uint8 substandardVersion = uint8(extraData.decodeSubstandardVersion());

    _validateSubstandard(zoneParameters, substandardVersion, extraData);

    return this.validateOrder.selector;
  }

  function authorizeOrder(ZoneParameters calldata /* zoneParameters*/ )
    external
    view
    isNotPaused
    returns (bytes4 authorizedOrderMagicValue)
  {
    return this.authorizeOrder.selector;
  }

  function _validateSubstandard(
    ZoneParameters calldata zoneParameters,
    uint8 substandardVersion,
    bytes calldata extraData
  ) internal view {
    address token;
    uint256 id;
    uint8 comparisonEnum;
    bytes32 traitKey;
    bytes32 expectedTraitValue;

    // If substandard version is 0, token address and id are first item of the consideration
    if (substandardVersion == 0) {
      // Decode traitKey from extraData
      traitKey = abi.decode(extraData[1:], (bytes32));

      // Get the token address from the first consideration item
      token = zoneParameters.consideration[0].token;

      // Get the id from the first consideration item
      id = zoneParameters.consideration[0].identifier;

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);

      traitComparisons[0] =
        TraitComparison({token: token, id: id, comparisonEnum: 0, traitValue: bytes32(0), traitKey: traitKey});

      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 1) {
      // Decode comparisonEnum, expectedTraitValue, and traitKey from extraData
      (comparisonEnum, traitKey, expectedTraitValue) = abi.decode(extraData[1:], (uint8, bytes32, bytes32));
      //TODO do we want to check multiple considerations?
      // Get the token address from the first offer item
      token = zoneParameters.offer[0].token;

      // Get the id from the first offer item
      id = zoneParameters.offer[0].identifier;

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);
      traitComparisons[0] = TraitComparison({
        token: token,
        comparisonEnum: comparisonEnum,
        traitValue: expectedTraitValue,
        traitKey: traitKey,
        id: id
      });

      _checkTraits(traitComparisons);
    } else {
      revert UnsupportedSubstandard(substandardVersion);
    }
  }

  function _checkTraits(TraitComparison[] memory traitComparisons) internal view {
    for (uint256 i; i < traitComparisons.length; ++i) {
      // Get the token address from the TraitComparison
      address token = traitComparisons[i].token;

      // Get the id from the TraitComparison
      uint256 id = traitComparisons[i].id;

      // Get the comparisonEnum from the TraitComparison
      uint256 comparisonEnum = traitComparisons[i].comparisonEnum;

      // Get the traitKey from the TraitComparison
      bytes32 traitKey = traitComparisons[i].traitKey;

      // Get the expectedTraitValue from the TraitComparison
      bytes32 expectedTraitValue = traitComparisons[i].traitValue;

      // Get the actual trait value for the given token, id, and traitKey
      bytes32 actualTraitValue = IERC7496(token).getTraitValue(id, traitKey);

      // If comparisonEnum is 0, actualTraitValue should be equal to the expectedTraitValue
      if (comparisonEnum == 0) {
        if (expectedTraitValue != actualTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // If comparisonEnum is 1, actualTraitValue should not be equal to the expectedTraitValue
      } else if (comparisonEnum == 1) {
        if (expectedTraitValue == actualTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // If comparisonEnum is 2, actualTraitValue should be less than the expectedTraitValue
      } else if (comparisonEnum == 2) {
        if (actualTraitValue >= expectedTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // If comparisonEnum is 3, actualTraitValue should be less than or equal to the expectedTraitValue
      } else if (comparisonEnum == 3) {
        if (actualTraitValue > expectedTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // If comparisonEnum is 4, actualTraitValue should be greater than the expectedTraitValue
      } else if (comparisonEnum == 4) {
        if (actualTraitValue <= expectedTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // If comparisonEnum is 5, actualTraitValue should be greater than or equal to the expectedTraitValue
      } else if (comparisonEnum == 5) {
        if (actualTraitValue < expectedTraitValue) {
          revert InvalidDynamicTraitValue(token, id, comparisonEnum, traitKey, expectedTraitValue, actualTraitValue);
        }
        // Revert if comparisonEnum is not 0-5
      } else {
        revert InvalidComparisonEnum(comparisonEnum);
      }
    }
  }

  /**
   * @dev Returns the metadata for this zone.
   *
   * @return name The name of the zone.
   * @return schemas The schemas that the zone implements.
   */
  function getSeaportMetadata() external pure returns (string memory name, Schema[] memory schemas) {
    schemas = new Schema[](1);
    schemas[0].id = 3003; //todo figure out the correct sip proposal id for sip6 decoding/encoding
    schemas[0].metadata = new bytes(0);

    return ('ODNFVZone', schemas);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC165, ZoneInterface) returns (bool) {
    return interfaceId == type(ZoneInterface).interfaceId || super.supportsInterface(interfaceId);
  }
}
