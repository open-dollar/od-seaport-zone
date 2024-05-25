// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';

/**
 * @title Adds support for ERC7496 to an existing ERC721
 * @author OpenFi Foundation
 * @notice IERC7496 events are never emitted since NFVState is tracked in Vault721
 */
interface IVault721Adapter is IERC7496 {
  error Disabled();
  error UnknownTraitKeys();

  /**
   * @dev get NFV trait
   */
  function getTraitValue(uint256 _tokenId, bytes32 _traitKey) external view returns (bytes32);

  /**
   * @dev get NFV traits
   */
  function getTraitValues(uint256 _tokenId, bytes32[] calldata _traitKeys) external view returns (bytes32[] memory);

  /**
   * @dev return onchain data uri of trait details
   */
  function getTraitMetadataURI() external view returns (string memory _uri);



  /**
   * @dev setTrait is disabled; NFVState is found in Vault721
   */
  function setTrait(uint256, bytes32, bytes32) external;
}
