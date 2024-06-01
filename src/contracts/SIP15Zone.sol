// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC165} from '@openzeppelin/utils/introspection/ERC165.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';
import {SIP6Decoder} from 'shipyard-core/src/sips/lib/SIP6Decoder.sol';
import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';
import {SeaportInterface} from 'seaport-types/src/interfaces/SeaportInterface.sol';

import {
  AdvancedOrder,
  CriteriaResolver,
  Execution,
  Fulfillment,
  Order,
  OrderComponents
} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {SIP15ZoneEventsAndErrors} from '../interfaces/SIP15ZoneEventsAndErrors.sol';
import {ISIP15Zone} from '../interfaces/ISIP15Zone.sol';

/**
 * @title  ODSeaportZone
 * @author MrDeadce11 & stephankmin
 * @notice SIP15Zone is an implementation of SIP-15. It verifies that the dynamic traits of an NFT
 *         have not changed between the time of order creation and the time of order fulfillment.
 */
contract SIP15Zone is ERC165, ISIP15Zone, SIP15ZoneEventsAndErrors {
  using SIP6Decoder for bytes;

  bool public isPaused;
  address private _controller;
  // Set an operator that can instruct the zone to cancel or execute orders.
  address public operator;

  constructor() {}

  /**
   * @dev Validates an order.
   *
   * @param zoneParameters The context about the order fulfillment and any
   *                       supplied extraData.
   *
   * @return validOrderMagicValue The magic value that indicates a valid
   *                             ff order.
   */
  function validateOrder(ZoneParameters calldata zoneParameters) public view returns (bytes4 validOrderMagicValue) {
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

    // Decode substandard version from extraData using SIP-6 decoder
    uint8 substandardVersion = uint8(extraData.decodeSubstandardVersion());

    _validateSubstandard(zoneParameters, substandardVersion, extraData);

    return this.validateOrder.selector;
  }

  function authorizeOrder(ZoneParameters calldata /* zoneParameters*/ )
    external
    view
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
    bytes32[] memory traitKeys;
    bytes32[] memory expectedTraitValues;
    // If substandard version is 0, token address and id are first item of the consideration
    if (substandardVersion == 0) {
      // Decode traitKey from extraData
      (bytes32 traitKey) = abi.decode(extraData[1:], (bytes32));

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
      (comparisonEnum, traitKeys, expectedTraitValues) = abi.decode(extraData[1:], (uint8, bytes32[], bytes32[]));

      // Get the token address from the first offer item
      token = zoneParameters.offer[0].token;

      // Get the id from the first offer item
      id = zoneParameters.offer[0].identifier;

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](2);
      for (uint256 i; i < traitComparisons.length; i++) {
        traitComparisons[i] = TraitComparison({
          token: token,
          comparisonEnum: comparisonEnum,
          traitValue: expectedTraitValues[i],
          traitKey: traitKeys[i],
          id: id
        });
      }
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
    schemas[0].id = 15;
    schemas[0].metadata = new bytes(0);

    return ('SIP15Zone', schemas);
  }
  // validateOnSale

  function supportsInterface(bytes4 interfaceId) public view override(ERC165, ZoneInterface) returns (bool) {
    return interfaceId == type(ZoneInterface).interfaceId || super.supportsInterface(interfaceId);
  }
}
