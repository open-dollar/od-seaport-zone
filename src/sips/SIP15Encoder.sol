// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReceivedItem} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';

struct Substandard5Comparison {
  uint8[] comparisonEnums;
  address token;
  address traits;
  uint256 identifier;
  bytes32[] traitValues;
  bytes32[] traitKeys;
}

library SIP15Encoder {
  /**
   * @notice Generate a zone hash for an SIP15 contract that implements substandards 1 and/or 2, which
   *         derives its zoneHash from a single comparison enum, trait value and trait key
   * @param zoneParameters the zone parameters for the order being encoded
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function generateZoneHashForSubstandard1Efficient(
    ZoneParameters memory zoneParameters,
    bytes32 traitKey
  ) internal pure returns (bytes32) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;
    // Get the id from the first consideration item
    uint256 identifier = zoneParameters.consideration[0].identifier;

    return keccak256(abi.encodePacked(uint8(0), token, identifier, bytes32(0), traitKey));
  }
  /**
   * @notice Generate a zone hash for an SIP15 contract that implements substandard 1, which
   *         derives its zoneHash from the first offer item,  a single comparison enum, trait value and trait key
   * @param zoneParameters the zone parameters for the order being encoded
   * @param comparisonEnum the comparison enum 0 - 5
   * @param traitValue the expected value of the trait.
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */

  function generateZoneHashForSubstandard1(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes32) {
    // Get the token address from the first offer item
    address token = zoneParameters.offer[0].token;
    // Get the id from the first offer item
    uint256 identifier = zoneParameters.offer[0].identifier;
    return keccak256(abi.encodePacked(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  /**
   * @notice Generate a zone hash for an SIP15 contract that implements substandard 1, which
   *         derives its zoneHash from the first consideration item,  a single comparison enum, trait value and trait key
   * @param zoneParameters the zone parameters for the order being encoded
   * @param comparisonEnum the comparison enum 0 - 5
   * @param traitValue the expected value of the trait.
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function generateZoneHashForSubstandard2(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes32) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;
    // Get the id from the first consideration item
    uint256 identifier = zoneParameters.consideration[0].identifier;
    return keccak256(abi.encodePacked(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  function generateZoneHashForSubstandard5(Substandard5Comparison memory _substandard5Comparison)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        _substandard5Comparison.comparisonEnums,
        _substandard5Comparison.token,
        _substandard5Comparison.traits,
        _substandard5Comparison.identifier,
        _substandard5Comparison.traitValues,
        _substandard5Comparison.traitKeys
      )
    );
  }

  /**
   * @notice Generate a zone hash for an SIP15 contract that implements substandard 3, which
   *         derives its zoneHash from a single comparison enum, token address, token id, trait value and trait key
   * @param comparisonEnum the comparison enum 0 - 5
   * @param token the address of the collection
   * @param identifier the tokenId of the token to be checked
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   */
  function generateZoneHash(
    uint8 comparisonEnum,
    address token,
    uint256 identifier,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(abi.encode(comparisonEnum, token, identifier, traitValue, traitKey)));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-1 Efficient, which specifies the
   * first consideration item, comparison "equal to", single trait key, zero trait value
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function encodeSubstandard1Efficient(
    ZoneParameters memory zoneParameters,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;

    // Get the id from the first consideration item
    uint256 id = zoneParameters.consideration[0].identifier;
    return abi.encodePacked(uint8(0), abi.encode(0, token, id, traitKey, bytes32(0)));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-1, which specifies the
   *         first offer item, token address and id from first offer item
   * @param comparisonEnum the comparison enum 0 - 5
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   */
  function encodeSubstandard1(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first offer item
    address token = zoneParameters.offer[0].token;

    // Get the id from the first offer item
    uint256 id = zoneParameters.offer[0].identifier;
    return abi.encodePacked(uint8(0x01), abi.encode(comparisonEnum, token, id, traitKey, traitValue));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-2, which specifies
   *    the token and identifier from the first consideration item as well as a comparison enum, trait key and trait value
   * @param zoneParameters memory zoneParameters,
   * @param comparisonEnum The comparison enum 0 - 5
   * @param traitValue The expecta value of the trait
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function encodeSubstandard2(
    ZoneParameters memory zoneParameters,
    uint8 comparisonEnum,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    // Get the token address from the first consideration item
    address token = zoneParameters.consideration[0].token;

    // Get the id from the first consideration item
    uint256 identifier = zoneParameters.consideration[0].identifier;
    return abi.encodePacked(uint8(0x02), abi.encode(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-3,
   * which specifies a single comparison enum, token, identifier, traitValue and traitKey
   * @param comparisonEnum the comparison enum 0 - 5
   * @param token the address of the collection
   * @param identifier the tokenId of the token to be checked
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   */
  function encodeSubstandard3(
    uint8 comparisonEnum,
    address token,
    uint256 identifier,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x03), abi.encode(comparisonEnum, token, identifier, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-4, which specifies a single comparison
   * enum and token and multiple identifiers,  single trait key and trait value.
   * each comparison is against a single identifier and a single traitValue with a single tratKey.
   * @param comparisonEnum the comparison enum 0 - 5
   * @param token the address of the collection
   * @param identifiers the tokenId of the token to be checked
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   * @param traitValue the expected value of the trait.
   */
  function encodeSubstandard4(
    uint8 comparisonEnum,
    address token,
    uint256[] memory identifiers,
    bytes32 traitValue,
    bytes32 traitKey
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x04), abi.encode(comparisonEnum, token, identifiers, traitValue, traitKey));
  }

  /**
   * @notice Encode extraData for SIP15-substandard-5, which specifies a single tokenIdentifier
   * @param comparisonStruct the struct of comparison data
   */
  function encodeSubstandard5(Substandard5Comparison memory comparisonStruct) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(0x05), abi.encode(comparisonStruct));
  }
}
