// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {Base64} from '@openzeppelin/utils/Base64.sol';
import {IVault721} from '@opendollar/interfaces/proxies/IVault721.sol';
import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';
import {IERC721} from '@openzeppelin/token/ERC721/IERC721.sol';
/**
 * @title Adds support for ERC7496 to an existing ERC721
 * @author MrDeadCe11, daopunk, pi0neerpat, CupOJoseph
 * @notice IERC7496 events are never emitted since NFVState is tracked in Vault721
 */

contract Vault721Adapter is IERC7496 {
  bytes32 public constant COLLATERAL = keccak256('COLLATERAL');
  bytes32 public constant DEBT = keccak256('DEBT');
  string public constant JSON_OPEN = '{"traits":{"';
  string public constant JSON_DISPLAYNAME = '":{"displayName":"';
  string public constant JSON_DATATYPE = '","dataType":{"type": "string","minLength":1},"validateOnSale": "';
  string public constant JSON_CLOSE = '}}';

  IVault721 public vault721;

  error Disabled();
  error UnknownTraitKeys();

  constructor(IVault721 _vault721) {
    vault721 = _vault721;
  }

  /**
   * @dev get NFV trait
   */
  function getTraitValue(uint256 _tokenId, bytes32 _traitKey) external view returns (bytes32) {
    return _getTraitValue(_tokenId, _traitKey);
  }

  /**
   * @dev get NFV traits
   */
  function getTraitValues(uint256 _tokenId, bytes32[] calldata _traitKeys) external view returns (bytes32[] memory) {
    uint256 l = _traitKeys.length;
    bytes32[] memory _traitValues = new bytes32[](l);

    for (uint256 i; i < l; i++) {
      _traitValues[i] = _getTraitValue(_tokenId, _traitKeys[i]);
    }
    return _traitValues;
  }

  /**
   * @dev return onchain data uri of trait details
   */
  function getTraitMetadataURI() external view returns (string memory _uri) {
    string memory _json = _formatJsonMetaData();
    _uri = string.concat('data:application/json;base64,', Base64.encode(bytes(_json)));
  }

  /**
   * @dev setTrait is disabled; NFVState is found in Vault721
   */
  function setTrait(uint256, bytes32, bytes32) external {
    revert Disabled();
  }

  /**
   * @dev get NFVState from Vault721
   * @notice return values are not hashed to enable enforceable condition in zone
   */
  function _getTraitValue(uint256 _tokenId, bytes32 _traitKey) internal view returns (bytes32) {
    IVault721.NFVState memory _nfvState = vault721.getNfvState(_tokenId);
    if (_traitKey == COLLATERAL) return bytes32(_nfvState.collateral);
    if (_traitKey == DEBT) return bytes32(_nfvState.debt);
    else revert UnknownTraitKeys();
  }

  function _formatJsonMetaData() internal pure returns (string memory _json) {
    _json = string.concat(
      JSON_OPEN,
      'collateral',
      JSON_DISPLAYNAME,
      'Collateral',
      JSON_DATATYPE,
      'requireUintGte"}',
      ',"debt',
      JSON_DISPLAYNAME,
      'Debt',
      JSON_DATATYPE,
      'requireUintLte"}',
      JSON_CLOSE
    );
  }
}
