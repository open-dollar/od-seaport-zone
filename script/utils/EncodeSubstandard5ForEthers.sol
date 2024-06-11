// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {SIP15Encoder, Substandard5Comparison} from "../../src/sips/SIP15Encoder.sol";

contract EncodeSubstandard5ForEthers {
    using SIP15Encoder for bytes;

    constructor() {}

    function encodeSubstandard5(
        uint8[] memory comparisonEnums,
        address token,
        address traits,
        uint256 identifier,
        bytes32[] memory traitValues,
        bytes32[] memory traitKeys
    ) public pure returns (bytes memory) {
        Substandard5Comparison memory newComparison = Substandard5Comparison({
            comparisonEnums: comparisonEnums,
            token: token,
            traits: traits,
            identifier: identifier,
            traitValues: traitValues,
            traitKeys: traitKeys
        });
        return SIP15Encoder.encodeSubstandard5(newComparison);
    }
}
