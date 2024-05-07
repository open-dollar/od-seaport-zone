// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

struct TraitComparison {
    address token;
    uint256 id;
    uint8 comparisonEnum;
    bytes32 traitValue;
    bytes32 traitKey;
}