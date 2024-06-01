// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import {ISIP15} from '../src/interfaces/ISIP15.sol';
import {BaseSIPDecoder} from 'shipyard-core/src/sips/lib/BaseSIPDecoder.sol';

library SIP6Decoder {
  // bytes4(keccak256('InvalidExtraDataEncoding(uint8)')
  uint256 constant INVALID_EXTRA_DATA_ENCODING_SELECTOR = 0xdefb1057;
  uint256 constant SELECTOR_MEMORY_OFFSET = 0x1c;
  uint256 constant _32_BIT_MASK = 0xffffffff;

  error InvalidExtraData();

  /**
   * @notice Read the SIP15 substandard version byte from the extraData field of a SIP15 encoded bytes array.
   * @param extraData bytes calldata
   */
  function decodeSubstandardVersion(bytes calldata extraData) internal pure returns (bytes1 substandard) {
    return BaseSIPDecoder.decodeSubstandardVersion(extraData);
  }
}
