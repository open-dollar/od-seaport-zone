// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReceivedItem} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import 'forge-std/console2.sol';

library SIP15Encoder {
  /**
   * @notice Generate a zone hash for an SIP15 contract that implements substandards 1 and/or 2, which
   *         derives its zoneHash from a single comparison enum, trait value and trait key
   * @param zoneParameters the zone parameters for the order being encoded
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function generateZoneHash(ZoneParameters calldata zoneParameters, bytes32 traitKey) internal pure returns (bytes32) {
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
    ZoneParameters calldata zoneParameters,
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
    ZoneParameters calldata zoneParameters,
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
    ZoneParameters calldata zoneParameters,
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
    ZoneParameters calldata zoneParameters,
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
   * @param zoneParameters calldata zoneParameters,
   * @param comparisonEnum The comparison enum 0 - 5
   * @param traitValue The expecta value of the trait
   * @param traitKey the bytes32 encoded trait key for checking a trait on an ERC7496 token
   */
  function encodeSubstandard2(
    ZoneParameters calldata zoneParameters,
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
   * @notice Encode extraData for SIP15-substandard-3, which specifies a hash that the hash of
   *         the receivedItems array must match
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
   * @notice Encode extraData for SIP15-substandard-4, which specifies a list of orderHashes
   *         that are forbidden from being included in the same fulfillment
   * @param forbiddenOrderHashes The list of forbidden orderHashes
   */
  function encodeSubstandard4(bytes32[] memory forbiddenOrderHashes) internal pure returns (bytes memory) {
    return abi.encodePacked(uint8(4), abi.encode(forbiddenOrderHashes));
  }
}
