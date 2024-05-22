// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC7496} from 'shipyard-core/src/dynamic-traits/interfaces/IERC7496.sol';
import {IVault721} from '@opendollar/interfaces/proxies/IVault721.sol';

/**
 * @notice IERC7496 events are never emitted since NFVState is tracked in Vault721
 */
contract Vault721Adapter is IERC7496 {
  bytes32 public constant COLLATERAL = keccak256('COLLATERAL');
  bytes32 public constant DEBT = keccak256('DEBT');

  IVault721 public vault721;

  error Disabled();
  error UnknownTraitKeys();

  constructor(IVault721 _vault721) {
    vault721 = _vault721;
  }

  /**
   * @dev get NFV trait
   */
  function getTraitValue(uint256 _tokenId, bytes32 _traitKey) public view returns (bytes32) {
    return _getTraitValue(_tokenId, _traitKey);
  }

  /**
   * @dev get NFV traits
   */
  function getTraitValues(uint256 _tokenId, bytes32[] calldata _traitKeys) external view returns (bytes32[] memory) {
    uint256 l = _traitKeys.length;
    bytes32[] memory _traitValues = new bytes32[](l);

    for (uint256 i; i < l; i++) {
      _traitValues[i] = getTraitValue(_tokenId, _traitKeys[i]);
    }
    return _traitValues;
  }

  /**
   * @dev ???
   */
  function getTraitMetadataURI() external view returns (string memory _uri) {
    _uri = '?';
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
}
