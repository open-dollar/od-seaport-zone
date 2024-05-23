// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {Test, console} from 'forge-std/Test.sol';
import {Vault721Adapter} from 'src/contracts/Vault721Adapter.sol';
import {IVault721} from '@opendollar/interfaces/proxies/IVault721.sol';

struct nfvValue {
  uint256 collateral;
  uint256 debt;
}

contract Base is Test {
  bytes32 public constant C = keccak256('COLLATERAL');
  bytes32 public constant D = keccak256('DEBT');

  Vault721Adapter public adapter;
  IVault721 public vault721;

  function setUp() public virtual {
    vault721 = IVault721(address(0x420));
    adapter = new Vault721Adapter(vault721);
  }

  modifier nfvValues(nfvValue memory _nfvValue) {
    vm.assume(_nfvValue.collateral > 0);
    vm.assume(_nfvValue.debt >= 0);
    _;
  }

  function _mockNfvStateCall(nfvValue memory _nfvValue) internal nfvValues(_nfvValue) {
    IVault721.NFVState memory nfvState;
    nfvState.collateral = _nfvValue.collateral;
    nfvState.debt = _nfvValue.debt;
    vm.mockCall(address(vault721), abi.encodeWithSelector(IVault721.getNfvState.selector), abi.encode(nfvState));
  }
}

contract Unit_Vault721Adapter_SetUp is Base {
  function test_initialize() public {
    assertTrue(adapter.vault721() == vault721);
  }

  function test_constants() public {
    assertTrue(adapter.COLLATERAL() == C);
    assertTrue(adapter.DEBT() == D);
  }

  function test_mockCall(uint256 _tokenId, nfvValue memory _nfvValue) public nfvValues(_nfvValue) {
    vm.assume(_tokenId > 0);
    _mockNfvStateCall(_nfvValue);
    bytes32 _traitValueCollateral = adapter.getTraitValue(_tokenId, C);
    assertTrue(_traitValueCollateral > 0);
    bytes32 _traitValueDebt = adapter.getTraitValue(_tokenId, D);
    assertTrue(_traitValueDebt >= 0);
  }
}

contract Unit_Vault721Adapter is Base {
  function test_getTraitValue(uint256 _tokenId, nfvValue memory _nfvValue) public {
    _mockNfvStateCall(_nfvValue);
    bytes32 _traitValueCollateral = adapter.getTraitValue(_tokenId, C);
    assertEq(bytes32(_nfvValue.collateral), _traitValueCollateral);
    bytes32 _traitValueDebt = adapter.getTraitValue(_tokenId, D);
    assertEq(bytes32(_nfvValue.debt), _traitValueDebt);
  }

  function test_getTraitValueRevert(uint256 _tokenId, bytes32 _traitKey, nfvValue memory _nfvValue) public {
    vm.assume(_traitKey != C && _traitKey != D);
    _mockNfvStateCall(_nfvValue);
    vm.expectRevert(abi.encodePacked(bytes4((keccak256('UnknownTraitKeys()')))));
    adapter.getTraitValue(_tokenId, _traitKey);
  }

  function test_getTraitValues(uint256 _tokenId, nfvValue memory _nfvValue) public {
    bytes32[] memory _traitKeys = new bytes32[](2);
    _traitKeys[0] = C;
    _traitKeys[1] = D;

    _mockNfvStateCall(_nfvValue);
    (bool _ok, bytes memory _traitValues) = address(adapter).call{value: 0}(
      abi.encodeWithSignature('getTraitValues(uint256,bytes32[])', _tokenId, _traitKeys)
    );
    require(_ok, 'call fail');
    (bytes32 _res1, bytes32 _res2, bytes32 _res3, bytes32 _res4) =
      abi.decode(_traitValues, (bytes32, bytes32, bytes32, bytes32));

    /// @notice to view emitted logs, run `forge t -vvvv`
    emit log_named_bytes('** Return Bytes **', _traitValues);
    emit log_named_bytes32('Result 1: 32 byte pieces of data', _res1);
    emit log_named_bytes32('Result 2: 2 pieces of data total', _res2);
    emit log_named_bytes32('Result 3: 1st piece of data ----', _res3);
    emit log_named_bytes32('Result 4: 2nd piece of data ----', _res4);

    assertEq(bytes32(_nfvValue.collateral), _res3);
    assertEq(bytes32(_nfvValue.debt), _res4);
  }

  function test_getTraitValuesReverseParams(uint256 _tokenId, nfvValue memory _nfvValue) public {
    bytes32[] memory _traitKeys = new bytes32[](2);
    _traitKeys[0] = D;
    _traitKeys[1] = C;

    _mockNfvStateCall(_nfvValue);
    (bool _ok, bytes memory _traitValues) = address(adapter).call{value: 0}(
      abi.encodeWithSignature('getTraitValues(uint256,bytes32[])', _tokenId, _traitKeys)
    );
    require(_ok, 'call fail');
    (bytes32 _res1, bytes32 _res2, bytes32 _res3, bytes32 _res4) =
      abi.decode(_traitValues, (bytes32, bytes32, bytes32, bytes32));

    assertEq(bytes32(_nfvValue.debt), _res3);
    assertEq(bytes32(_nfvValue.collateral), _res4);
  }

  function test_getTraitValuesRevert(
    uint256 _tokenId,
    bytes32 _traitKey1,
    bytes32 _traitKey2,
    nfvValue memory _nfvValue
  ) public {
    bytes32[] memory _traitKeys = new bytes32[](2);
    vm.assume(_traitKey1 != C && _traitKey1 != D);
    vm.assume(_traitKey2 != C && _traitKey2 != D);
    _traitKeys[0] = _traitKey1;
    _traitKeys[1] = _traitKey2;

    _mockNfvStateCall(_nfvValue);
    vm.expectRevert(abi.encodePacked(bytes4((keccak256('UnknownTraitKeys()')))));
    (bool _ok, bytes memory _traitValues) = address(adapter).call{value: 0}(
      abi.encodeWithSignature('getTraitValues(uint256,bytes32[])', _tokenId, _traitKeys)
    );
  }

  /**
   * @notice encoded json data that OpenSea uses to enforce rules about traits:
   *
   * {"traits":{"collateral":{"displayName":"Collateral","dataType":{"type": "string","minLength":1},"validateOnSale": "requireEq"},"debt":{"displayName":"Debt","dataType":{"type": "string","minLength":1},"validateOnSale": "requireEq"}}}
   * to base64
   * eyJ0cmFpdHMiOnsiY29sbGF0ZXJhbCI6eyJkaXNwbGF5TmFtZSI6IkNvbGxhdGVyYWwiLCJkYXRhVHlwZSI6eyJ0eXBlIjogInN0cmluZyIsIm1pbkxlbmd0aCI6MX0sInZhbGlkYXRlT25TYWxlIjogInJlcXVpcmVVaW50R3RlIn0sImRlYnQiOnsiZGlzcGxheU5hbWUiOiJEZWJ0IiwiZGF0YVR5cGUiOnsidHlwZSI6ICJzdHJpbmciLCJtaW5MZW5ndGgiOjF9LCJ2YWxpZGF0ZU9uU2FsZSI6ICJyZXF1aXJlVWludEx0ZSJ9fX0==
   */
  function test_getTraitMetadataURI() public {
    string memory _uri = adapter.getTraitMetadataURI();
    emit log_named_string('Metadata URI', _uri);
    assertEq(
      bytes32(bytes(_uri)),
      bytes32(
        bytes(
          'data:application/json;base64,eyJ0cmFpdHMiOnsiY29sbGF0ZXJhbCI6eyJkaXNwbGF5TmFtZSI6IkNvbGxhdGVyYWwiLCJkYXRhVHlwZSI6eyJ0eXBlIjogInN0cmluZyIsIm1pbkxlbmd0aCI6MX0sInZhbGlkYXRlT25TYWxlIjogInJlcXVpcmVVaW50R3RlIn0sImRlYnQiOnsiZGlzcGxheU5hbWUiOiJEZWJ0IiwiZGF0YVR5cGUiOnsidHlwZSI6ICJzdHJpbmciLCJtaW5MZW5ndGgiOjF9LCJ2YWxpZGF0ZU9uU2FsZSI6ICJyZXF1aXJlVWludEx0ZSJ9fX0='
        )
      )
    );
  }

  function test_setTraitValues_Revert(uint256 _tokenId, bytes32 _traitKey, bytes32 _traitValue) public {
    vm.expectRevert(abi.encodePacked(bytes4((keccak256('Disabled()')))));
    adapter.setTrait(_tokenId, _traitKey, _traitValue);
  }
}
