// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

/**
 * todo remove this after open-dollar package is added to this repo
 */
interface IVault721 {
  struct NFVState {
    bytes32 cType;
    uint256 collateral;
    uint256 debt;
    uint256 lastBlockNumber;
    uint256 lastBlockTimestamp;
    address safeHandler;
  }

  /**
   * @dev get nfv state by vault id
   */
  function getNfvState(uint256 _vaultId) external view returns (NFVState memory);
}
