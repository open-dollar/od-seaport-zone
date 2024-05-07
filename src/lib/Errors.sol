// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface Errors {
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
}
