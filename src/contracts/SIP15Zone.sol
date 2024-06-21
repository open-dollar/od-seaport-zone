// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC165} from '@openzeppelin/utils/introspection/ERC165.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';
import {SIP15Decoder} from '../sips/SIP15Decoder.sol';
import {Substandard5Comparison} from '../sips/SIP15Encoder.sol';
import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

import {SIP15ZoneEventsAndErrors} from '../interfaces/SIP15ZoneEventsAndErrors.sol';
import {ISIP15Zone} from '../interfaces/ISIP15Zone.sol';

/**
 * @title  SIP15Zone
 * @author MrDeadce11 & stephankmin
 * @notice SIP15Zone is an implementation of SIP-15. It verifies the state of dynamic traits after a transfer.
 * it can be used with substandards 1-5.  see Substandard documentation here https://github.com/open-dollar/SIPs/blob/main/SIPS/sip-15.md
 */
contract SIP15Zone is ERC165, ISIP15Zone, SIP15ZoneEventsAndErrors {
  using SIP15Decoder for bytes;

  // Set an operator that can instruct the zone to cancel or execute orders.

  constructor() {}

  /**
   * @dev Validates an order. called after order is fulfilled and offers and considerations have been transfered
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

    _validateSubstandard(substandardVersion, extraData);

    return this.validateOrder.selector;
  }

  /**
   * @dev called before order fulfillment. no authorization is required for this zone.
   * @return authorizedOrderMagicValue the bytes4 magic order value that authorizes the order
   */
  function authorizeOrder(ZoneParameters calldata /* zoneParameters*/ )
    external
    view
    returns (bytes4 authorizedOrderMagicValue)
  {
    return this.authorizeOrder.selector;
  }
  /**
   * @dev decodes extraData acording to the substandard and then checks the traits according to
   * the designated comparison enum/enums.  See SIP15encoder for encoding details.
   */

  function _validateSubstandard(uint8 substandardVersion, bytes calldata extraData) internal view {
    address token;
    uint256 id;
    uint8 comparisonEnum;
    bytes32 traitKey;
    bytes32 traitValue;
    // If substandard version is 0, token address and id are first item of the consideration
    if (substandardVersion == 0) {
      // Decode traitKey from extraData
      (comparisonEnum, token, id, traitValue, traitKey) = extraData.decodeSubstandard1Efficient();

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);

      traitComparisons[0] = TraitComparison({
        token: token,
        id: id,
        comparisonEnum: comparisonEnum,
        traitValue: traitValue,
        traitKey: traitKey
      });

      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 1) {
      // Decode traitKey from extraData
      (comparisonEnum, token, id, traitValue, traitKey) = extraData.decodeSubstandard1();

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);

      traitComparisons[0] = TraitComparison({
        token: token,
        id: id,
        comparisonEnum: comparisonEnum,
        traitValue: traitValue,
        traitKey: traitKey
      });

      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 2) {
      // Decode traitKey from extraData
      (comparisonEnum, token, id, traitValue, traitKey) = extraData.decodeSubstandard2();

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);

      traitComparisons[0] = TraitComparison({
        token: token,
        id: id,
        comparisonEnum: comparisonEnum,
        traitValue: traitValue,
        traitKey: traitKey
      });

      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 3) {
      // Decode traitKey from extraData
      (comparisonEnum, token, id, traitValue, traitKey) = extraData.decodeSubstandard3();

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](1);

      traitComparisons[0] = TraitComparison({
        token: token,
        id: id,
        comparisonEnum: comparisonEnum,
        traitValue: traitValue,
        traitKey: traitKey
      });

      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 4) {
      uint256[] memory ids;
      uint256 len = ids.length;

      // Decode traitKey from extraData
      (comparisonEnum, token, ids, traitValue, traitKey) = extraData.decodeSubstandard4();

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](len);

      for (uint256 i; i < len; i++) {
        traitComparisons[i] = TraitComparison({
          token: token,
          comparisonEnum: comparisonEnum,
          traitValue: traitValue,
          traitKey: traitKey,
          id: ids[i]
        });
      }
      // Check the trait
      _checkTraits(traitComparisons);
    } else if (substandardVersion == 5) {
      // Decode comparisonEnum, expectedTraitValue, and traitKey from extraData
      (Substandard5Comparison memory substandard5Comparison) = extraData.decodeSubstandard5();
      uint256 len = substandard5Comparison.comparisonEnums.length;

      if (len != substandard5Comparison.traitValues.length || len != substandard5Comparison.traitKeys.length) {
        revert InvalidArrayLength();
      }

      // Declare the TraitComparison array
      TraitComparison[] memory traitComparisons = new TraitComparison[](len);

      for (uint256 i; i < len; i++) {
        traitComparisons[i] = TraitComparison({
          token: substandard5Comparison.traits == address(0)
            ? substandard5Comparison.token
            : substandard5Comparison.traits,
          comparisonEnum: substandard5Comparison.comparisonEnums[i],
          traitValue: substandard5Comparison.traitValues[i],
          traitKey: substandard5Comparison.traitKeys[i],
          id: substandard5Comparison.identifier
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
