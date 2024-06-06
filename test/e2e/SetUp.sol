
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {DeployForTest, ODTest, COLLAT, DEBT, TKN} from '@opendollar/test/e2e/Common.t.sol';
import {ERC20ForTest} from '@opendollar/test/mocks/ERC20ForTest.sol';
import {ISAFEEngine} from '@opendollar/interfaces/ISAFEEngine.sol';
import {BaseOrderTest} from 'seaport/test/foundry/utils/BaseOrderTest.sol';
import {ODProxy} from '@opendollar/contracts/proxies/ODProxy.sol';
import {
  IBaseOracle
} from '@opendollar/interfaces/oracles/IBaseOracle.sol';

contract SetUp is DeployForTest, ODTest, BaseOrderTest {
      uint256 public constant MINT_AMOUNT = 1000 ether;
  uint256 public constant MULTIPLIER = 10; // for over collateralization
  uint256 public debtCeiling;

  address public aliceProxy;
  address public bobProxy;

  ERC20ForTest public tokenForTest;

    function setUp() public virtual override {
        super.setUp();
        run();

    for (uint256 i = 0; i < collateralTypes.length; i++) {
      bytes32 _cType = collateralTypes[i];
      taxCollector.taxSingle(_cType);
    }

    vm.label(deployer, 'Deployer');
    vm.label(alice, 'Alice');
    vm.label(bob, 'Bob');

    vm.startPrank(deployer); // no governor on test deployment
    accountingEngine.modifyParameters('extraSurplusReceiver', abi.encode(address(alice)));
    aliceProxy = deployOrFind(alice);
    bobProxy = deployOrFind(bob);
    vm.label(aliceProxy, 'AliceProxy');
    vm.label(bobProxy, 'BobProxy');

    tokenForTest = ERC20ForTest(address(collateral[TKN]));
    tokenForTest.mint(MINT_AMOUNT);

    ISAFEEngine.SAFEEngineParams memory params = safeEngine.params();
    debtCeiling = params.safeDebtCeiling;
    }

    function deployOrFind(address owner) public returns (address) {
    address proxy = vault721.getProxy(owner);
    if (proxy == address(0)) {
      return address(vault721.build(owner));
    } else {
      return proxy;
    }
  }

function _setCollateralPrice(bytes32 _collateral, uint256 _price) internal {
    IBaseOracle _oracle = oracleRelayer.cParams(_collateral).oracle;
    vm.mockCall(
      address(_oracle), abi.encodeWithSelector(IBaseOracle.getResultWithValidity.selector), abi.encode(_price, true)
    );
    vm.mockCall(address(_oracle), abi.encodeWithSelector(IBaseOracle.read.selector), abi.encode(_price));
    oracleRelayer.updateCollateralPrice(_collateral);
  }

  function _collectFees(bytes32 _cType, uint256 _timeToWarp) internal {
    vm.warp(block.timestamp + _timeToWarp);
    taxCollector.taxSingle(_cType);
  }

  function depositCollatAndGenDebt(
    bytes32 _cType,
    uint256 _safeId,
    uint256 _collatAmount,
    uint256 _deltaWad,
    address _proxy
  ) public {
    bytes memory payload = abi.encodeWithSelector(
      basicActions.lockTokenCollateralAndGenerateDebt.selector,
      address(safeManager),
      address(collateralJoin[_cType]),
      address(coinJoin),
      _safeId,
      _collatAmount,
      _deltaWad
    );
    ODProxy(_proxy).execute(address(basicActions), payload);
  }

    function genDebt(uint256 _safeId, uint256 _deltaWad, address _proxy) public {
    bytes memory payload = abi.encodeWithSelector(
      basicActions.generateDebt.selector, address(safeManager), address(coinJoin), _safeId, _deltaWad
    );
    ODProxy(_proxy).execute(address(basicActions), payload);
  }

}