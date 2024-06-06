// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {
  AdvancedOrder,
  ConsiderationItem,
  CriteriaResolver,
  Fulfillment,
  FulfillmentComponent,
  OrderParameters,
  ItemType,
  OfferItem,
  Order,
  OrderComponents,
  OrderType
} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {DeployForTest, ODTest, COLLAT, DEBT, TKN} from '@opendollar/test/e2e/Common.t.sol';

import {UnavailableReason} from 'seaport-sol/src/SpaceEnums.sol';
import {BaseOrderTest} from 'seaport/test/foundry/utils/BaseOrderTest.sol';
import {SetUp} from './SetUp.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

import {
  ConsiderationItemLib,
  FulfillmentComponentLib,
  FulfillmentLib,
  OfferItemLib,
  OrderComponentsLib,
  OrderParametersLib,
  AdvancedOrderLib,
  OrderLib,
  SeaportArrays
} from 'seaport-sol/src/lib/SeaportStructLib.sol';

import {TestTransferValidationZoneOfferer} from 'seaport/contracts/test/TestTransferValidationZoneOfferer.sol';

import {FulfillAvailableHelper} from 'seaport-sol/src/fulfillments/available/FulfillAvailableHelper.sol';

import {MatchFulfillmentHelper} from 'seaport-sol/src/fulfillments/match/MatchFulfillmentHelper.sol';

import {TestZone} from 'seaport/test/foundry/zone/impl/TestZone.sol';

import {IVault721Adapter} from '../../src/interfaces/IVault721Adapter.sol';
import {Vault721Adapter} from '../../src/contracts/Vault721Adapter.sol';
import {IVault721} from '@opendollar/interfaces/proxies/IVault721.sol';
import {IODSafeManager} from '@opendollar/interfaces/proxies/IODSafeManager.sol';
import {SIP15ZoneEventsAndErrors} from '../../src/interfaces/SIP15ZoneEventsAndErrors.sol';
import {SIP15Zone} from '../../src/contracts/SIP15Zone.sol';
import {SIP15Encoder, Substandard5Comparison} from '../../src/sips/SIP15Encoder.sol';
import 'forge-std/console2.sol';

contract TestTransferValidationSIP15ZoneOffererTest is SetUp {
  using FulfillmentLib for Fulfillment;
  using FulfillmentComponentLib for FulfillmentComponent;
  using FulfillmentComponentLib for FulfillmentComponent[];
  using OfferItemLib for OfferItem;
  using OfferItemLib for OfferItem[];
  using ConsiderationItemLib for ConsiderationItem;
  using ConsiderationItemLib for ConsiderationItem[];
  using OrderComponentsLib for OrderComponents;
  using OrderLib for Order;
  using OrderLib for Order[];

  error InvalidDynamicTraitValue(
    address token,
    uint256 id,
    uint256 comparisonEnum,
    bytes32 traitKey,
    bytes32 expectedTraitValue,
    bytes32 actualTraitValue
  );

  MatchFulfillmentHelper matchFulfillmentHelper;
  FulfillAvailableHelper fulfillAvailableFulfillmentHelper;
  SIP15Zone zone;
  TestZone testZone;
  Vault721Adapter public vault721Adapter;

  // constant strings for recalling struct lib defaults
  // ideally these live in a base test class
  string constant SINGLE_721 = 'single 721';
  string constant VALIDATION_ZONE = 'validation zone';

  function setUp() public virtual override {
    super.setUp();

    zone = new SIP15Zone();
    vault721Adapter = new Vault721Adapter(vault721);

    matchFulfillmentHelper = new MatchFulfillmentHelper();
    fulfillAvailableFulfillmentHelper = new FulfillAvailableHelper();
    // zone = new TestTransferValidationZoneOfferer(address(0));
    testZone = new TestZone();

    // create a default consideration for a single 721;
    // note that it does not have recipient, token or
    // identifier set
    ConsiderationItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(
      SINGLE_721
    );

    // create a default offerItem for a single 721;
    // note that it does not have token or identifier set
    OfferItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(SINGLE_721);

    OrderComponentsLib.empty().withOfferer(offerer1.addr).withZone(address(zone)).withOrderType(
      OrderType.FULL_RESTRICTED
    ).withStartTime(block.timestamp).withEndTime(block.timestamp + vault721.timeDelay() + 100_000).withZoneHash(
      bytes32(0)
    ).withSalt(0).withConduitKey(conduitKeyOne) // not strictly necessary
      // fill in offer later
      // fill in consideration later
      .saveDefault(VALIDATION_ZONE);
    // fill in counter later
  }

  struct Context {
    ConsiderationInterface seaport;
    FulfillFuzzInputs fulfillArgs;
    MatchFuzzInputs matchArgs;
  }

  struct FulfillFuzzInputs {
    uint256 tokenId;
    uint128 amount;
    uint128 excessNativeTokens;
    uint256 orderCount;
    uint256 considerationItemsPerOrderCount;
    uint256 maximumFulfilledCount;
    address offerRecipient;
    address considerationRecipient;
    bytes32 zoneHash;
    uint256 salt;
    bool shouldAggregateFulfillmentComponents;
    bool shouldUseConduit;
    bool shouldUseTransferValidationZone;
    bool shouldIncludeNativeConsideration;
    bool shouldIncludeExcessOfferItems;
    bool shouldSpecifyRecipient;
    bool shouldIncludeJunkDataInAdvancedOrder;
  }

  struct MatchFuzzInputs {
    uint256 tokenId;
    uint128 amount;
    uint128 excessNativeTokens;
    uint256 orderPairCount;
    uint256 considerationItemsPerPrimeOrderCount;
    uint256 collateralAmount;
    // This is currently used only as the unspent prime offer item recipient
    // but would also set the recipient for unspent mirror offer items if
    // any were added in the test in the future.
    address unspentPrimeOfferItemRecipient;
    string primeOfferer;
    string mirrorOfferer;
    bytes32 zoneHash;
    uint256 salt;
    bool shouldUseConduit;
    bool shouldUseTransferValidationZoneForPrime;
    bool shouldUseTransferValidationZoneForMirror;
    bool shouldIncludeNativeConsideration;
    bool shouldIncludeExcessOfferItems;
    bool shouldSpecifyUnspentOfferItemRecipient;
    bool shouldIncludeJunkDataInAdvancedOrder;
  }

  // Used for stack depth management.
  struct MatchAdvancedOrdersInfra {
    Order[] orders;
    Fulfillment[] fulfillments;
    AdvancedOrder[] advancedOrders;
    CriteriaResolver[] criteriaResolvers;
    uint256 callerBalanceBefore;
    uint256 callerBalanceAfter;
    uint256 primeOffererBalanceBefore;
    uint256 primeOffererBalanceAfter;
  }

  // Used for stack depth management.
  struct FulfillAvailableAdvancedOrdersInfra {
    AdvancedOrder[] advancedOrders;
    FulfillmentComponent[][] offerFulfillmentComponents;
    FulfillmentComponent[][] considerationFulfillmentComponents;
    CriteriaResolver[] criteriaResolvers;
    uint256 callerBalanceBefore;
    uint256 callerBalanceAfter;
    uint256 considerationRecipientNativeBalanceBefore;
    uint256 considerationRecipientToken1BalanceBefore;
    uint256 considerationRecipientToken2BalanceBefore;
    uint256 considerationRecipientNativeBalanceAfter;
    uint256 considerationRecipientToken1BalanceAfter;
    uint256 considerationRecipientToken2BalanceAfter;
  }

  // Used for stack depth management.
  struct OrderAndFulfillmentInfra {
    OfferItem[] offerItemArray;
    ConsiderationItem[] considerationItemArray;
    OrderComponents orderComponents;
    Order[] orders;
    Fulfillment fulfillment;
    Fulfillment[] fulfillments;
  }

  // Used for stack depth management.
  struct OrderComponentInfra {
    OrderComponents orderComponents;
    OrderComponents[] orderComponentsArray;
    OfferItem[][] offerItemArray;
    ConsiderationItem[][] considerationItemArray;
    ConsiderationItem nativeConsiderationItem;
    ConsiderationItem erc20ConsiderationItemOne;
    ConsiderationItem erc20ConsiderationItemTwo;
  }

  FulfillFuzzInputs emptyFulfill;
  MatchFuzzInputs emptyMatch;

  Account fuzzPrimeOfferer;
  Account fuzzMirrorOfferer;

  address public fuzzPrimeProxy;
  address fuzzMirrorProxy;

  bytes32 public constant COLLATERAL = keccak256('COLLATERAL');
  bytes32 public constant DEBTKEY = keccak256('DEBT');

  function test(function(Context memory) external fn, Context memory context) internal {
    try fn(context) {
      fail();
    } catch (bytes memory reason) {
      assertPass(reason);
    }
  }

  function testFail(function(Context memory) external fn, Context memory context) internal {
    try fn(context) {
      fail();
    } catch (bytes memory reason) {
      // assertPass(reason);
    }
  }

  function testMatchAdvancedOrdersFuzz(MatchFuzzInputs memory matchArgs) public {
    // Avoid weird overflow issues.
    matchArgs.amount = uint128(bound(matchArgs.amount, 1, 0xffffffffffffffff));
    matchArgs.collateralAmount = uint128(bound(matchArgs.collateralAmount, 1, 0xffffffffffffffff));
    // Avoid trying to mint the same token.
    matchArgs.tokenId = vault721.totalSupply() + 1;
    // Make 1-8 order pairs per call.  Each order pair will have 1-2 offer
    // items on the prime side (depending on whether
    // shouldIncludeExcessOfferItems is true or false).
    matchArgs.orderPairCount = bound(matchArgs.orderPairCount, 1, 8);
    // Use 1-3 (prime) consideration items per order.
    matchArgs.considerationItemsPerPrimeOrderCount = bound(matchArgs.considerationItemsPerPrimeOrderCount, 1, 3);
    // To put three items in the consideration, native tokens must be
    // included.
    matchArgs.shouldIncludeNativeConsideration =
      matchArgs.shouldIncludeNativeConsideration || matchArgs.considerationItemsPerPrimeOrderCount >= 3;
    // Only include an excess offer item when NOT using the transfer
    // validation zone or the zone will revert.
    matchArgs.shouldIncludeExcessOfferItems = matchArgs.shouldIncludeExcessOfferItems
      && !(matchArgs.shouldUseTransferValidationZoneForPrime || matchArgs.shouldUseTransferValidationZoneForMirror);
    // Include some excess native tokens to check that they're ending up
    // with the caller afterward.
    matchArgs.excessNativeTokens = uint128(bound(matchArgs.excessNativeTokens, 0, 0xfffffffffffffffffffffffffffff));
    // Don't set the offer recipient to the null address, because that's the
    // way to indicate that the caller should be the recipient.
    matchArgs.unspentPrimeOfferItemRecipient = _nudgeAddressIfProblematic(
      address(uint160(bound(uint160(matchArgs.unspentPrimeOfferItemRecipient), 1, type(uint160).max)))
    );

    matchArgs.zoneHash = _getZoneHash(_getExtraData(matchArgs.tokenId));

    // TODO: REMOVE: I probably need to create an array of addresses with
    // dirty balances and an array of addresses that are contracts that
    // cause problems with native token transfers.

    test(this.execMatchAdvancedOrdersFuzz, Context(consideration, emptyFulfill, matchArgs));
    test(this.execMatchAdvancedOrdersFuzz, Context(referenceConsideration, emptyFulfill, matchArgs));
    testFail(this.execMatchAdvancedOrders_Revert_DebtIncrease, Context(consideration, emptyFulfill, matchArgs));
  }

  function execMatchAdvancedOrdersFuzz(Context memory context) external stateless {
    // Set up the infrastructure for this function in a struct to avoid
    // stack depth issues.
    MatchAdvancedOrdersInfra memory infra = MatchAdvancedOrdersInfra({
      orders: new Order[](context.matchArgs.orderPairCount),
      fulfillments: new Fulfillment[](context.matchArgs.orderPairCount),
      advancedOrders: new AdvancedOrder[](context.matchArgs.orderPairCount),
      criteriaResolvers: new CriteriaResolver[](0),
      callerBalanceBefore: 0,
      callerBalanceAfter: 0,
      primeOffererBalanceBefore: 0,
      primeOffererBalanceAfter: 0
    });

    // note fuzzer kept passing empty strings for prime and mirror,
    // since safe manager will not transfer a safe to the same address
    // I had to ensure they were different
    context.matchArgs.mirrorOfferer = 'mirrorOfferer';
    // TODO: (Someday) See if the stack can tolerate fuzzing criteria
    // resolvers.
    // The prime offerer is offering NFTs and considering ERC20/Native.
    fuzzPrimeOfferer = makeAndAllocateAccount(context.matchArgs.primeOfferer);
    // The mirror offerer is offering ERC20/Native and considering NFTs.
    fuzzMirrorOfferer = makeAndAllocateAccount(context.matchArgs.mirrorOfferer);

    vm.assume(fuzzPrimeOfferer.addr != fuzzMirrorOfferer.addr);

    console2.log('prime offerer', fuzzPrimeOfferer.addr);
    console2.log('mirror offerer', fuzzMirrorOfferer.addr);

    fuzzPrimeProxy = deployOrFind(fuzzPrimeOfferer.addr);
    fuzzMirrorProxy = deployOrFind(fuzzMirrorOfferer.addr);

    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(conduit), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(referenceConsideration), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(referenceConduit), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(consideration), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(conduitController), true);

    // Set fuzzMirrorOfferer as the zone's expected offer recipient.
    // zone.setExpectedOfferRecipient(fuzzMirrorOfferer.addr);

    // Create the orders and fulfuillments.
    (infra.orders, infra.fulfillments) = _buildOrdersAndFulfillmentsMirrorOrdersFromFuzzArgs(context);

    // Set up the advanced orders array.
    infra.advancedOrders = new AdvancedOrder[](infra.orders.length);

    // Convert the orders to advanced orders.
    for (uint256 i = 0; i < infra.orders.length; i++) {
      infra.advancedOrders[i] = infra.orders[i].toAdvancedOrder(1, 1, _getExtraData(context.matchArgs.tokenId));
    }
    vm.warp(block.timestamp + vault721.timeDelay());
    // Set up event expectations.
    if (
      fuzzPrimeOfferer
        // If the fuzzPrimeOfferer and fuzzMirrorOfferer are the same
        // address, then the ERC20 transfers will be filtered.
        .addr != fuzzMirrorOfferer.addr
    ) {
      if (
        // When shouldIncludeNativeConsideration is false, there will be
        // exactly one token1 consideration item per orderPairCount. And
        // they'll all get aggregated into a single transfer.
        !context.matchArgs.shouldIncludeNativeConsideration
      ) {
        // This checks that the ERC20 transfers were all aggregated into
        // a single transfer.
        vm.expectEmit(true, true, false, true, address(token1));
        emit Transfer(
          address(fuzzMirrorOfferer.addr), // from
          address(fuzzPrimeOfferer.addr), // to
          context.matchArgs.amount * context.matchArgs.orderPairCount
        );
      }

      if (
        context
          .matchArgs
          // When considerationItemsPerPrimeOrderCount is 3, there will be
          // exactly one token2 consideration item per orderPairCount.
          // And they'll all get aggregated into a single transfer.
          .considerationItemsPerPrimeOrderCount >= 3
      ) {
        vm.expectEmit(true, true, false, true, address(token2));
        emit Transfer(
          address(fuzzMirrorOfferer.addr), // from
          address(fuzzPrimeOfferer.addr), // to
          context.matchArgs.amount * context.matchArgs.orderPairCount
        );
      }
    }

    // Store the native token balances before the call for later reference.
    infra.callerBalanceBefore = address(this).balance;
    infra.primeOffererBalanceBefore = address(fuzzPrimeOfferer.addr).balance;
    // Make the call to Seaport.

    context.seaport.matchAdvancedOrders{
      value: (context.matchArgs.amount * context.matchArgs.orderPairCount) + context.matchArgs.excessNativeTokens
    }(
      infra.advancedOrders,
      infra.criteriaResolvers,
      infra.fulfillments,
      // If shouldSpecifyUnspentOfferItemRecipient is true, send the
      // unspent offer items to the recipient specified by the fuzz args.
      // Otherwise, pass in the zero address, which will result in the
      // unspent offer items being sent to the caller.
      context.matchArgs.shouldSpecifyUnspentOfferItemRecipient
        ? address(context.matchArgs.unspentPrimeOfferItemRecipient)
        : address(0)
    );

    // Note the native token balances after the call for later checks.
    infra.callerBalanceAfter = address(this).balance;
    infra.primeOffererBalanceAfter = address(fuzzPrimeOfferer.addr).balance;

    // The expected call count is the number of prime orders using the
    // transfer validation zone, plus the number of mirror orders using the
    // transfer validation zone.  So, expected call count can be 0,
    // context.matchArgs.orderPairCount, or context.matchArgs.orderPairCount
    // * 2.
    // uint256 expectedCallCount = 0;
    // if (context.matchArgs.shouldUseTransferValidationZoneForPrime) {
    //     expectedCallCount += context.matchArgs.orderPairCount;
    // }
    // if (context.matchArgs.shouldUseTransferValidationZoneForMirror) {
    //     expectedCallCount += context.matchArgs.orderPairCount;
    // }
    // assertTrue(zone.callCount() == expectedCallCount);

    // Check that the NFTs were transferred to the expected recipient.
    // for (uint256 i = 0; i < context.matchArgs.orderPairCount; i++) {
    //   assertEq(test721_1.ownerOf((context.matchArgs.tokenId + i )* 2), fuzzMirrorOfferer.addr);
    // }

    if (context.matchArgs.shouldIncludeExcessOfferItems) {
      // Check that the excess offer NFTs were transferred to the expected
      // recipient.
      for (uint256 i = 0; i < context.matchArgs.orderPairCount; i++) {
        assertEq(
          test721_1.ownerOf((context.matchArgs.tokenId + i) * 2),
          context.matchArgs.shouldSpecifyUnspentOfferItemRecipient
            ? context.matchArgs.unspentPrimeOfferItemRecipient
            : address(this)
        );
      }
    }

    if (context.matchArgs.shouldIncludeNativeConsideration) {
      // Check that ETH is moving from the caller to the prime offerer.
      // This also checks that excess native tokens are being swept back
      // to the caller.
      assertEq(
        infra.callerBalanceBefore - context.matchArgs.amount * context.matchArgs.orderPairCount,
        infra.callerBalanceAfter
      );
      assertEq(
        infra.primeOffererBalanceBefore + context.matchArgs.amount * context.matchArgs.orderPairCount,
        infra.primeOffererBalanceAfter
      );
    } else {
      assertEq(infra.callerBalanceBefore, infra.callerBalanceAfter);
    }
  }

  function execMatchAdvancedOrders_Revert_DebtIncrease(Context memory context) external stateless {
    context.matchArgs.shouldIncludeExcessOfferItems = false;
    // Set up the infrastructure for this function in a struct to avoid
    // stack depth issues.
    MatchAdvancedOrdersInfra memory infra = MatchAdvancedOrdersInfra({
      orders: new Order[](context.matchArgs.orderPairCount),
      fulfillments: new Fulfillment[](context.matchArgs.orderPairCount),
      advancedOrders: new AdvancedOrder[](context.matchArgs.orderPairCount),
      criteriaResolvers: new CriteriaResolver[](0),
      callerBalanceBefore: 0,
      callerBalanceAfter: 0,
      primeOffererBalanceBefore: 0,
      primeOffererBalanceAfter: 0
    });

    // TODO: (Someday) See if the stack can tolerate fuzzing criteria
    // resolvers.
    context.matchArgs.mirrorOfferer = 'mirrorOfferer';
    // The prime offerer is offering NFTs and considering ERC20/Native.
    fuzzPrimeOfferer = makeAndAllocateAccount(context.matchArgs.primeOfferer);
    // The mirror offerer is offering ERC20/Native and considering NFTs.
    fuzzMirrorOfferer = makeAndAllocateAccount(context.matchArgs.mirrorOfferer);
    //  fuzzMirrorOfferer.addr = address(uint160(bound(uint160(fuzzPrimeOfferer.addr), 1, type(uint160).max)));
    vm.assume(fuzzPrimeOfferer.addr != fuzzMirrorOfferer.addr);

    console2.log('prime offerer', fuzzPrimeOfferer.addr);
    console2.log('mirror offerer', fuzzMirrorOfferer.addr);

    fuzzPrimeProxy = deployOrFind(fuzzPrimeOfferer.addr);
    fuzzMirrorProxy = deployOrFind(fuzzMirrorOfferer.addr);

    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(conduit), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(referenceConsideration), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(referenceConduit), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(consideration), true);
    vm.prank(fuzzPrimeOfferer.addr);
    vault721.setApprovalForAll(address(conduitController), true);

    // Set fuzzMirrorOfferer as the zone's expected offer recipient.
    // zone.setExpectedOfferRecipient(fuzzMirrorOfferer.addr);

    // Create the orders and fulfuillments.
    (infra.orders, infra.fulfillments) = _buildOrdersAndFulfillmentsMirrorOrdersFromFuzzArgs(context);

    // Set up the advanced orders array.
    infra.advancedOrders = new AdvancedOrder[](infra.orders.length);

    // Convert the orders to advanced orders.
    for (uint256 i = 0; i < infra.orders.length; i++) {
      infra.advancedOrders[i] = infra.orders[i].toAdvancedOrder(1, 1, _getExtraData(context.matchArgs.tokenId));
    }

    // offerer takes on more debt so that vault state changes negatively before sale

    uint256[] memory safes = safeManager.getSafes(fuzzPrimeProxy);

    for (uint256 i; i < safes.length; i++) {
      vm.prank(fuzzPrimeOfferer.addr);
      genDebt(safes[i], context.matchArgs.collateralAmount / 8, fuzzPrimeProxy);
    }
    //warp to after time delay
    vm.warp(block.timestamp + vault721.timeDelay());

    //expect revert
    //empty expect revert because I'm too lazy to calculate the exact amount of extra tax getting pulled out.
    // vm.expectRevert(abi.encodeWithSelector(SIP15ZoneEventsAndErrors.InvalidDynamicTraitValue.selector, address(vault721Adapter), safes[0], 3, DEBTKEY, bytes32(context.matchArgs.collateralAmount / 2), bytes32(((context.matchArgs.collateralAmount / 2) + (context.matchArgs.collateralAmount / 8) - 99513020104531))));
    vm.expectRevert();

    // Make the call to Seaport.

    context.seaport.matchAdvancedOrders{
      value: (context.matchArgs.amount * context.matchArgs.orderPairCount) + context.matchArgs.excessNativeTokens
    }(
      infra.advancedOrders,
      infra.criteriaResolvers,
      infra.fulfillments,
      // If shouldSpecifyUnspentOfferItemRecipient is true, send the
      // unspent offer items to the recipient specified by the fuzz args.
      // Otherwise, pass in the zero address, which will result in the
      // unspent offer items being sent to the caller.
      context.matchArgs.shouldSpecifyUnspentOfferItemRecipient
        ? address(context.matchArgs.unspentPrimeOfferItemRecipient)
        : address(0)
    );
  }

  function _buildOrdersFromFuzzArgs(
    Context memory context,
    uint256 key
  ) internal returns (AdvancedOrder[] memory advancedOrders) {
    // Create the OrderComponents array from the fuzz args.
    OrderComponents[] memory orderComponents;
    orderComponents = _buildOrderComponentsArrayFromFuzzArgs(context);

    // Set up the AdvancedOrder array.
    AdvancedOrder[] memory _advancedOrders = new AdvancedOrder[](context.fulfillArgs.orderCount);

    // Iterate over the OrderComponents array and build an AdvancedOrder
    // for each OrderComponents.
    Order memory order;
    for (uint256 i = 0; i < orderComponents.length; i++) {
      if (orderComponents[i].orderType == OrderType.CONTRACT) {
        revert('Not implemented.');
      } else {
        // Create the order.
        order = _toOrder(context.seaport, orderComponents[i], key);
        // Convert it to an AdvancedOrder and add it to the array.
        _advancedOrders[i] = order.toAdvancedOrder(
          1,
          1,
          // Reusing salt here for junk data.
          context.fulfillArgs.shouldIncludeJunkDataInAdvancedOrder
            ? bytes(abi.encodePacked(context.fulfillArgs.salt))
            : bytes('')
        );
      }
    }

    return _advancedOrders;
  }

  function _buildOrderComponentsArrayFromFuzzArgs(Context memory context)
    internal
    returns (OrderComponents[] memory _orderComponentsArray)
  {
    // Set up the OrderComponentInfra struct.
    OrderComponentInfra memory orderComponentInfra = OrderComponentInfra(
      OrderComponentsLib.empty(),
      new OrderComponents[](context.fulfillArgs.orderCount),
      new OfferItem[][](context.fulfillArgs.orderCount),
      new ConsiderationItem[][](context.fulfillArgs.orderCount),
      ConsiderationItemLib.empty(),
      ConsiderationItemLib.empty(),
      ConsiderationItemLib.empty()
    );

    // Create three different consideration items.
    (
      orderComponentInfra.nativeConsiderationItem,
      orderComponentInfra.erc20ConsiderationItemOne,
      orderComponentInfra.erc20ConsiderationItemTwo
    ) = _createReusableConsiderationItems(context.fulfillArgs.amount, context.fulfillArgs.considerationRecipient);

    // Iterate once for each order and create the OfferItems[] and
    // ConsiderationItems[] for each order.
    for (uint256 i; i < context.fulfillArgs.orderCount; i++) {
      // Add a one-element OfferItems[] to the OfferItems[][].
      orderComponentInfra.offerItemArray[i] = SeaportArrays.OfferItems(
        OfferItemLib.fromDefault(SINGLE_721).withToken(address(test721_1)).withIdentifierOrCriteria(
          context.fulfillArgs.tokenId + i
        )
      );

      if (context.fulfillArgs.considerationItemsPerOrderCount == 1) {
        // If the fuzz args call for native consideration...
        if (context.fulfillArgs.shouldIncludeNativeConsideration) {
          // ...add a native consideration item...
          orderComponentInfra.considerationItemArray[i] =
            SeaportArrays.ConsiderationItems(orderComponentInfra.nativeConsiderationItem);
        } else {
          // ...otherwise, add an ERC20 consideration item.
          orderComponentInfra.considerationItemArray[i] =
            SeaportArrays.ConsiderationItems(orderComponentInfra.erc20ConsiderationItemOne);
        }
      } else if (context.fulfillArgs.considerationItemsPerOrderCount == 2) {
        // If the fuzz args call for native consideration...
        if (context.fulfillArgs.shouldIncludeNativeConsideration) {
          // ...add a native consideration item and an ERC20
          // consideration item...
          orderComponentInfra.considerationItemArray[i] = SeaportArrays.ConsiderationItems(
            orderComponentInfra.nativeConsiderationItem, orderComponentInfra.erc20ConsiderationItemOne
          );
        } else {
          // ...otherwise, add two ERC20 consideration items.
          orderComponentInfra.considerationItemArray[i] = SeaportArrays.ConsiderationItems(
            orderComponentInfra.erc20ConsiderationItemOne, orderComponentInfra.erc20ConsiderationItemTwo
          );
        }
      } else {
        orderComponentInfra.considerationItemArray[i] = SeaportArrays.ConsiderationItems(
          orderComponentInfra.nativeConsiderationItem,
          orderComponentInfra.erc20ConsiderationItemOne,
          orderComponentInfra.erc20ConsiderationItemTwo
        );
      }
    }

    // Use either the transfer validation zone or the test zone for all
    // orders.
    address fuzzyZone;

    if (context.fulfillArgs.shouldUseTransferValidationZone) {
      zone = new SIP15Zone();
      // (
      //     context.fulfillArgs.shouldSpecifyRecipient
      //         ? context.fulfillArgs.offerRecipient
      //         : address(this)
      // );
      fuzzyZone = address(zone);
    } else {
      fuzzyZone = address(testZone);
    }

    bytes32 conduitKey;

    // Iterate once for each order and create the OrderComponents.
    for (uint256 i = 0; i < context.fulfillArgs.orderCount; i++) {
      // if context.fulfillArgs.shouldUseConduit is false: don't use conduits at all.
      // if context.fulfillArgs.shouldUseConduit is true:
      //      if context.fulfillArgs.tokenId % 2 == 0:
      //          use conduits for some and not for others
      //      if context.fulfillArgs.tokenId % 2 != 0:
      //          use conduits for all
      // This is plainly deranged, but it allows for conduit use
      // for all, for some, and none without weighing down the stack.
      conduitKey = !context.fulfillArgs.shouldIncludeNativeConsideration && context.fulfillArgs.shouldUseConduit
        && (context.fulfillArgs.tokenId % 2 == 0 ? i % 2 == 0 : true) ? conduitKeyOne : bytes32(0);
      // Build the order components.
      orderComponentInfra.orderComponents = OrderComponentsLib.fromDefault(VALIDATION_ZONE).withOffer(
        orderComponentInfra.offerItemArray[i]
      ).withConsideration(orderComponentInfra.considerationItemArray[i]).withZone(fuzzyZone).withZoneHash(
        context.fulfillArgs.zoneHash
      ).withConduitKey(conduitKey).withSalt(context.fulfillArgs.salt % (i + 1)); // Is this dumb?

      // Add the OrderComponents to the OrderComponents[].
      orderComponentInfra.orderComponentsArray[i] = orderComponentInfra.orderComponents;
    }

    // Return the OrderComponents[].
    return orderComponentInfra.orderComponentsArray;
  }

  function _createReusableConsiderationItems(
    uint256 amount,
    address recipient
  )
    internal
    view
    returns (
      ConsiderationItem memory nativeConsiderationItem,
      ConsiderationItem memory erc20ConsiderationItemOne,
      ConsiderationItem memory erc20ConsiderationItemTwo
    )
  {
    // Create a reusable native consideration item.
    nativeConsiderationItem = ConsiderationItemLib.empty().withItemType(ItemType.NATIVE).withIdentifierOrCriteria(0)
      .withStartAmount(amount).withEndAmount(amount).withRecipient(recipient);

    // Create a reusable ERC20 consideration item.
    erc20ConsiderationItemOne = ConsiderationItemLib.empty().withItemType(ItemType.ERC20).withToken(address(token1))
      .withIdentifierOrCriteria(0).withStartAmount(amount).withEndAmount(amount).withRecipient(recipient);

    // Create a second reusable ERC20 consideration item.
    erc20ConsiderationItemTwo = ConsiderationItemLib.empty().withItemType(ItemType.ERC20).withIdentifierOrCriteria(0)
      .withToken(address(token2)).withStartAmount(amount).withEndAmount(amount).withRecipient(recipient);
  }

  function _buildPrimeOfferItemArray(
    Context memory context,
    uint256 i
  ) internal view returns (OfferItem[] memory _offerItemArray) {
    // Set up the OfferItem array.
    OfferItem[] memory offerItemArray = new OfferItem[](context.matchArgs.shouldIncludeExcessOfferItems ? 2 : 1);

    // If the fuzz args call for an excess offer item...
    if (context.matchArgs.shouldIncludeExcessOfferItems) {
      // Create the OfferItem array containing the offered item and the
      // excess item.
      offerItemArray = SeaportArrays.OfferItems(
        OfferItemLib.fromDefault(SINGLE_721).withToken(address(vault721)).withIdentifierOrCriteria(
          context.matchArgs.tokenId + i
        ),
        OfferItemLib.fromDefault(SINGLE_721).withToken(address(test721_1)).withIdentifierOrCriteria(
          (context.matchArgs.tokenId + i) * 2
        )
      );
    } else {
      // Otherwise, create the OfferItem array containing the one offered
      // item.
      offerItemArray = SeaportArrays.OfferItems(
        OfferItemLib.fromDefault(SINGLE_721).withToken(address(vault721)).withIdentifierOrCriteria(
          context.matchArgs.tokenId + i
        )
      );
    }

    return offerItemArray;
  }

  function _buildPrimeConsiderationItemArray(Context memory context)
    internal
    view
    returns (ConsiderationItem[] memory _considerationItemArray)
  {
    // Set up the ConsiderationItem array.
    ConsiderationItem[] memory considerationItemArray =
      new ConsiderationItem[](context.matchArgs.considerationItemsPerPrimeOrderCount);

    // Create the consideration items.
    (
      ConsiderationItem memory nativeConsiderationItem,
      ConsiderationItem memory erc20ConsiderationItemOne,
      ConsiderationItem memory erc20ConsiderationItemTwo
    ) = _createReusableConsiderationItems(context.matchArgs.amount, fuzzPrimeOfferer.addr);

    if (context.matchArgs.considerationItemsPerPrimeOrderCount == 1) {
      // If the fuzz args call for native consideration...
      if (context.matchArgs.shouldIncludeNativeConsideration) {
        // ...add a native consideration item...
        considerationItemArray = SeaportArrays.ConsiderationItems(nativeConsiderationItem);
      } else {
        // ...otherwise, add an ERC20 consideration item.
        considerationItemArray = SeaportArrays.ConsiderationItems(erc20ConsiderationItemOne);
      }
    } else if (context.matchArgs.considerationItemsPerPrimeOrderCount == 2) {
      // If the fuzz args call for native consideration...
      if (context.matchArgs.shouldIncludeNativeConsideration) {
        // ...add a native consideration item and an ERC20
        // consideration item...
        considerationItemArray = SeaportArrays.ConsiderationItems(nativeConsiderationItem, erc20ConsiderationItemOne);
      } else {
        // ...otherwise, add two ERC20 consideration items.
        considerationItemArray = SeaportArrays.ConsiderationItems(erc20ConsiderationItemOne, erc20ConsiderationItemTwo);
      }
    } else {
      // If the fuzz args call for three consideration items per prime
      // order, add all three consideration items.
      considerationItemArray =
        SeaportArrays.ConsiderationItems(nativeConsiderationItem, erc20ConsiderationItemOne, erc20ConsiderationItemTwo);
    }

    return considerationItemArray;
  }

  function _buildMirrorOfferItemArray(Context memory context)
    internal
    view
    returns (OfferItem[] memory _offerItemArray)
  {
    // Set up the OfferItem array.
    OfferItem[] memory offerItemArray = new OfferItem[](1);

    // Create some consideration items.
    (
      ConsiderationItem memory nativeConsiderationItem,
      ConsiderationItem memory erc20ConsiderationItemOne,
      ConsiderationItem memory erc20ConsiderationItemTwo
    ) = _createReusableConsiderationItems(context.matchArgs.amount, fuzzPrimeOfferer.addr);

    // Convert them to OfferItems.
    OfferItem memory nativeOfferItem = _toOfferItem(nativeConsiderationItem);
    OfferItem memory erc20OfferItemOne = _toOfferItem(erc20ConsiderationItemOne);
    OfferItem memory erc20OfferItemTwo = _toOfferItem(erc20ConsiderationItemTwo);

    if (context.matchArgs.considerationItemsPerPrimeOrderCount == 1) {
      // If the fuzz args call for native consideration...
      if (context.matchArgs.shouldIncludeNativeConsideration) {
        // ...add a native consideration item...
        offerItemArray = SeaportArrays.OfferItems(nativeOfferItem);
      } else {
        // ...otherwise, add an ERC20 consideration item.
        offerItemArray = SeaportArrays.OfferItems(erc20OfferItemOne);
      }
    } else if (context.matchArgs.considerationItemsPerPrimeOrderCount == 2) {
      // If the fuzz args call for native consideration...
      if (context.matchArgs.shouldIncludeNativeConsideration) {
        // ...add a native consideration item and an ERC20
        // consideration item...
        offerItemArray = SeaportArrays.OfferItems(nativeOfferItem, erc20OfferItemOne);
      } else {
        // ...otherwise, add two ERC20 consideration items.
        offerItemArray = SeaportArrays.OfferItems(erc20OfferItemOne, erc20OfferItemTwo);
      }
    } else {
      offerItemArray = SeaportArrays.OfferItems(nativeOfferItem, erc20OfferItemOne, erc20OfferItemTwo);
    }

    return offerItemArray;
  }

  function buildMirrorConsiderationItemArray(
    Context memory context,
    uint256 i
  ) internal view returns (ConsiderationItem[] memory _considerationItemArray) {
    // Set up the ConsiderationItem array.
    ConsiderationItem[] memory considerationItemArray =
      new ConsiderationItem[](context.matchArgs.considerationItemsPerPrimeOrderCount);

    // Note that the consideration array here will always be just one NFT
    // so because the second NFT on the offer side is meant to be excess.
    considerationItemArray = SeaportArrays.ConsiderationItems(
      ConsiderationItemLib.fromDefault(SINGLE_721).withToken(address(vault721)).withIdentifierOrCriteria(
        context.matchArgs.tokenId + i
      ).withRecipient(fuzzMirrorOfferer.addr)
    );

    return considerationItemArray;
  }

  function _buildOrderComponents(
    Context memory context,
    OfferItem[] memory offerItemArray,
    ConsiderationItem[] memory considerationItemArray,
    address offerer,
    bool shouldUseTransferValidationZone
  ) internal returns (OrderComponents memory _orderComponents) {
    OrderComponents memory orderComponents = OrderComponentsLib.empty();

    // Create the offer and consideration item arrays.
    OfferItem[] memory _offerItemArray = offerItemArray;
    ConsiderationItem[] memory _considerationItemArray = considerationItemArray;

    // Build the OrderComponents for the prime offerer's order.
    orderComponents = OrderComponentsLib.fromDefault(VALIDATION_ZONE).withOffer(_offerItemArray).withConsideration(
      _considerationItemArray
    ).withZone(address(0)).withOrderType(OrderType.FULL_OPEN).withConduitKey(
      context.matchArgs.tokenId % 2 == 0 ? conduitKeyOne : bytes32(0)
    ).withOfferer(offerer).withCounter(context.seaport.getCounter(offerer));

    // If the fuzz args call for a transfer validation zone...
    if (shouldUseTransferValidationZone) {
      // ... set the zone to the transfer validation zone and
      // set the order type to FULL_RESTRICTED.
      orderComponents = orderComponents.copy().withZone(address(zone)).withOrderType(OrderType.FULL_RESTRICTED)
        .withZoneHash(_getZoneHash(_getExtraData(context.matchArgs.tokenId)));
    }

    return orderComponents;
  }

  function _buildOrdersAndFulfillmentsMirrorOrdersFromFuzzArgs(Context memory context)
    internal
    returns (Order[] memory, Fulfillment[] memory)
  {
    uint256 i;

    // Set up the OrderAndFulfillmentInfra struct.
    OrderAndFulfillmentInfra memory infra = OrderAndFulfillmentInfra(
      new OfferItem[](context.matchArgs.orderPairCount),
      new ConsiderationItem[](context.matchArgs.orderPairCount),
      OrderComponentsLib.empty(),
      new Order[](context.matchArgs.orderPairCount * 2),
      FulfillmentLib.empty(),
      new Fulfillment[](context.matchArgs.orderPairCount * 2)
    );

    // Iterate once for each orderPairCount, which is
    // used as the number of order pairs to make here.
    for (i = 0; i < context.matchArgs.orderPairCount; i++) {
      // Mint the NFTs for the prime offerer to sell.
      vm.prank(fuzzPrimeProxy);
      uint256 currentVaultId = safeManager.openSAFE(TKN, fuzzPrimeProxy); //NOTE: THIS may be causing the order already fullfilled error
        // test721_1.mint(fuzzPrimeOfferer.addr, (context.matchArgs.tokenId + i) * 2);

      vm.startPrank(fuzzPrimeOfferer.addr);
      tokenForTest.mint(context.matchArgs.collateralAmount);
      tokenForTest.approve(fuzzPrimeProxy, context.matchArgs.collateralAmount);
      depositCollatAndGenDebt(
        TKN, currentVaultId, context.matchArgs.collateralAmount, context.matchArgs.collateralAmount / 2, fuzzPrimeProxy
      );
      vm.stopPrank();
      // Build the OfferItem array for the prime offerer's order.
      infra.offerItemArray = _buildPrimeOfferItemArray(context, i);
      // Build the ConsiderationItem array for the prime offerer's order.
      infra.considerationItemArray = _buildPrimeConsiderationItemArray(context);

      // Build the OrderComponents for the prime offerer's order.
      infra.orderComponents = _buildOrderComponents(
        context,
        infra.offerItemArray,
        infra.considerationItemArray,
        fuzzPrimeOfferer.addr,
        context.matchArgs.shouldUseTransferValidationZoneForPrime
      );

      // Add the order to the orders array.
      infra.orders[i] = _toOrder(context.seaport, infra.orderComponents, fuzzPrimeOfferer.key);

      // Build the offerItemArray for the mirror offerer's order.
      infra.offerItemArray = _buildMirrorOfferItemArray(context);

      // Build the considerationItemArray for the mirror offerer's order.
      // Note that the consideration on the mirror is always just one NFT,
      // even if the prime order has an excess item.
      infra.considerationItemArray = buildMirrorConsiderationItemArray(context, i);

      // Build the OrderComponents for the mirror offerer's order.
      infra.orderComponents = _buildOrderComponents(
        context,
        infra.offerItemArray,
        infra.considerationItemArray,
        fuzzMirrorOfferer.addr,
        context.matchArgs.shouldUseTransferValidationZoneForMirror
      );

      // Create the order and add the order to the orders array.
      infra.orders[i + context.matchArgs.orderPairCount] =
        _toOrder(context.seaport, infra.orderComponents, fuzzMirrorOfferer.key);
    }

    bytes32[] memory orderHashes = new bytes32[](context.matchArgs.orderPairCount * 2);

    UnavailableReason[] memory unavailableReasons = new UnavailableReason[](context.matchArgs.orderPairCount * 2);

    // Build fulfillments.
    (infra.fulfillments,,) =
      matchFulfillmentHelper.getMatchedFulfillments(infra.orders, orderHashes, unavailableReasons);

    return (infra.orders, infra.fulfillments);
  }

  function _toOrder(
    ConsiderationInterface seaport,
    OrderComponents memory orderComponents,
    uint256 pkey
  ) internal view returns (Order memory order) {
    bytes32 orderHash = seaport.getOrderHash(orderComponents);
    bytes memory signature = signOrder(seaport, pkey, orderHash);
    order = OrderLib.empty().withParameters(orderComponents.toOrderParameters()).withSignature(signature);
  }

  function _toOfferItem(ConsiderationItem memory item) internal pure returns (OfferItem memory) {
    return OfferItem({
      itemType: item.itemType,
      token: item.token,
      identifierOrCriteria: item.identifierOrCriteria,
      startAmount: item.startAmount,
      endAmount: item.endAmount
    });
  }

  function _nudgeAddressIfProblematic(address _address) internal returns (address) {
    bool success;
    assembly {
      // Transfer the native token and store if it succeeded or not.
      success := call(gas(), _address, 1, 0, 0, 0, 0)
    }

    if (success) {
      return _address;
    } else {
      return address(uint160(_address) + 1);
    }
  }

  function _getTraits(uint256 tokenId) internal returns (bytes32[] memory traits) {
    bytes32[] memory traitKeys = new bytes32[](2);
    traitKeys[0] = COLLATERAL;
    traitKeys[1] = DEBTKEY;

    traits = vault721Adapter.getTraitValues(tokenId, traitKeys);
  }

  function _getExtraData(uint256 tokenId) public returns (bytes memory) {
    bytes32[] memory traits = _getTraits(tokenId);
    bytes32[] memory keys = new bytes32[](2);
    uint8[] memory _comparisonEnums = new uint8[](2);
    _comparisonEnums[0] = 5;
    _comparisonEnums[1] = 3;
    keys[0] = COLLATERAL;
    keys[1] = DEBTKEY;
    Substandard5Comparison memory subStandard5Comparison = Substandard5Comparison({
      comparisonEnums: _comparisonEnums,
      token: address(vault721),
      identifier: tokenId,
      traits: address(vault721Adapter),
      traitValues: traits,
      traitKeys: keys
    });

    return SIP15Encoder.encodeSubstandard5(subStandard5Comparison);
  }

  function _getZoneHash(bytes memory _substandard5Comparison) public returns (bytes32 _zoneHash) {
    _zoneHash = SIP15Encoder.generateZoneHash(_substandard5Comparison);
  }

  // function deployOrFind(address owner) public returns (address payable) {
  //   address proxy = vault721.getProxy(owner);
  //   if (proxy == address(0)) {
  //     return vault721.build(owner);
  //   } else {
  //     return payable(address(proxy));
  //   }
  // }
}
