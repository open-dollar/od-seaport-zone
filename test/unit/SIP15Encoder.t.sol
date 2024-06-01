// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import {Test, console} from 'forge-std/Test.sol';
import {SIP15Encoder} from '../../src/sips/SIP15Encoder.sol';
import {ZoneParameters, Schema} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {
  ConsiderationItemLib,
  FulfillmentComponentLib,
  FulfillmentLib,
  OfferItemLib,
  ZoneParametersLib,
  OrderComponentsLib,
  OrderParametersLib,
  AdvancedOrderLib,
  OrderLib,
  SeaportArrays
} from 'seaport-sol/src/lib/SeaportStructLib.sol';

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
  SpentItem,
  ReceivedItem,
  OrderComponents,
  OrderType
} from 'seaport-types/src/lib/ConsiderationStructs.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

contract SIP15Encoder_Unit_test is Test {
  using OfferItemLib for OfferItem;
  using OfferItemLib for OfferItem[];
  using ConsiderationItemLib for ConsiderationItem;
  using ConsiderationItemLib for ConsiderationItem[];
  using OrderComponentsLib for OrderComponents;
  using OrderParametersLib for OrderParameters;
  using OrderLib for Order;
  using OrderLib for Order[];

  string constant SINGLE_721 = 'single 721';
  string constant SINGLE_721_Order = '721 order';

  struct FuzzInputs {
    uint256 tokenId;
    uint256 tokenId2;
    uint128 amount;
    address token;
    address token2;
    address erc20;
    address offerer;
    address recipient;
    bytes32 zoneHash;
    uint256 salt;
    address fulfiller;
    address seaport;
    bytes32 traitKey;
    bytes32 traitValue;
    uint8 comparisonEnum;
  }

  struct Context {
    ConsiderationInterface seaport;
    FuzzInputs fuzzInputs;
  }

  function setUp() public {
    // create a default offerItem for a single 721;
    // note that it does not have token or identifier set
    OfferItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(SINGLE_721);

    ConsiderationItemLib.empty().withItemType(ItemType.ERC721).withStartAmount(1).withEndAmount(1).saveDefault(
      SINGLE_721
    );

    OrderComponentsLib.empty().withOrderType(OrderType.FULL_RESTRICTED).withStartTime(block.timestamp).withEndTime(
      block.timestamp + 10
    ).withSalt(0).saveDefault(SINGLE_721_Order);
  }

  function test_EncodeSubstandard1EfficientFuzz(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1Efficient(zoneParams, context.fuzzInputs.traitKey);
  }

  function test_EncodeSubstandard1(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
  }

  function test_EncodeSubstandard2(Context memory context) public view {
    ZoneParameters memory zoneParams = _createZoneParams(context);
    this.encodeSubstandard1(
      zoneParams, context.fuzzInputs.comparisonEnum, context.fuzzInputs.traitValue, context.fuzzInputs.traitKey
    );
  }

  function test_EncodeSubstandard3(Context memory context) public view {
    this.encodeSubstandard3(
      context.fuzzInputs.comparisonEnum,
      context.fuzzInputs.token,
      context.fuzzInputs.tokenId,
      context.fuzzInputs.traitValue,
      context.fuzzInputs.traitKey
    );
  }

  function encodeSubstandard1Efficient(ZoneParameters calldata zoneParams, bytes32 _traitKey) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1Efficient(zoneParams, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);

    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitKey, bytes32 traitValue) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));
    assertEq(substandard, 1);
    assertEq(comparisonEnum, 0);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, bytes32(0));
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function encodeSubstandard1(
    ZoneParameters calldata zoneParams,
    uint8 _comparisonEnum,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1(zoneParams, _comparisonEnum, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitKey, bytes32 traitValue) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 1);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, zoneParams.offer[0].token);
    assertEq(id, zoneParams.offer[0].identifier);
  }

  function encodeSubstandard2(
    ZoneParameters calldata zoneParams,
    uint8 _comparisonEnum,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData = SIP15Encoder.encodeSubstandard1(zoneParams, _comparisonEnum, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 id, bytes32 traitKey, bytes32 traitValue) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 1);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, zoneParams.consideration[0].token);
    assertEq(id, zoneParams.consideration[0].identifier);
  }

  function encodeSubstandard3(
    uint8 _comparisonEnum,
    address _token,
    uint256 _identifier,
    bytes32 _traitValue,
    bytes32 _traitKey
  ) public view {
    bytes memory encodedData =
      SIP15Encoder.encodeSubstandard3(_comparisonEnum, _token, _identifier, _traitValue, _traitKey);
    uint8 substandard = uint8(this.decodeSubstandardVersion(encodedData, 0));

    bytes memory trimmedData = this.trimSubstandard(encodedData);
    (uint8 comparisonEnum, address token, uint256 identifier, bytes32 traitValue, bytes32 traitKey) =
      abi.decode(trimmedData, (uint8, address, uint256, bytes32, bytes32));

    assertEq(substandard, 3);
    assertEq(comparisonEnum, _comparisonEnum);
    assertEq(traitKey, _traitKey);
    assertEq(traitValue, _traitValue);
    assertEq(token, _token);
    assertEq(identifier, _identifier);
  }

  function trimSubstandard(bytes calldata dataToTrim) external pure returns (bytes memory data) {
    data = dataToTrim[1:];
  }

  function decodeSubstandardVersion(
    bytes calldata extraData,
    uint256 sipDataStartRelativeOffset
  ) external pure returns (bytes1 versionByte) {
    assembly {
      versionByte := shr(248, calldataload(add(extraData.offset, sipDataStartRelativeOffset)))
      versionByte := or(versionByte, iszero(versionByte))
      versionByte := shl(248, versionByte)
    }
  }
  //use fuzz inputs to create some zone params to test the encoder.

  function _createZoneParams(Context memory context) internal view returns (ZoneParameters memory zoneParameters) {
    // Avoid weird overflow issues.
    context.fuzzInputs.amount = uint128(bound(context.fuzzInputs.amount, 1, 0xffffffffffffffff));
    context.fuzzInputs.tokenId = bound(context.fuzzInputs.tokenId, 0, 0xfffffffff);
    //create offer item array from fuzz inputs
    OfferItem[] memory offerItemArray = _createOfferArray(context.fuzzInputs);
    //create consideration item array from fuzz inputs
    ConsiderationItem[] memory considerationItemArray = _createConsiderationArray(context.fuzzInputs);
    //create order components from fuzz inputs
    OrderComponents memory orderComponents =
      _buildOrderComponents(context.fuzzInputs, offerItemArray, considerationItemArray);
    //create order
    Order memory order = OrderLib.empty().withParameters(orderComponents.toOrderParameters());

    //create advanced order
    AdvancedOrder memory advancedOrder = order.toAdvancedOrder(1, 1, bytes(''));

    CriteriaResolver[] memory criteriaResolvers = new CriteriaResolver[](0);
    //create zone parameters
    zoneParameters = getZoneParameters(advancedOrder, context.fuzzInputs.fulfiller, criteriaResolvers);
  }

  function _createOfferArray(FuzzInputs memory _fuzzInputs) internal view returns (OfferItem[] memory _offerItems) {
    _offerItems = SeaportArrays.OfferItems(
      OfferItemLib.fromDefault(SINGLE_721).withToken(address(_fuzzInputs.token)).withIdentifierOrCriteria(
        _fuzzInputs.tokenId
      ),
      OfferItemLib.fromDefault(SINGLE_721).withToken(address(_fuzzInputs.token2)).withIdentifierOrCriteria(
        _fuzzInputs.tokenId % 7
      )
    );
  }

  function _createConsiderationArray(FuzzInputs memory _fuzzInputs)
    internal
    view
    returns (ConsiderationItem[] memory _considerationItemArray)
  {
    ConsiderationItem memory erc721ConsiderationItem = ConsiderationItemLib.fromDefault(SINGLE_721)
      .withIdentifierOrCriteria(_fuzzInputs.tokenId).withToken(_fuzzInputs.token).withStartAmount(1).withEndAmount(1)
      .withRecipient(_fuzzInputs.recipient);

    // Create a native consideration item.
    ConsiderationItem memory nativeConsiderationItem = ConsiderationItemLib.empty().withItemType(ItemType.NATIVE)
      .withIdentifierOrCriteria(0).withStartAmount(_fuzzInputs.amount).withEndAmount(_fuzzInputs.amount).withRecipient(
      _fuzzInputs.recipient
    );

    // Create a ERC20 consideration item.
    ConsiderationItem memory erc20ConsiderationItemOne = ConsiderationItemLib.empty().withItemType(ItemType.ERC20)
      .withToken(_fuzzInputs.erc20).withIdentifierOrCriteria(0).withStartAmount(_fuzzInputs.amount).withEndAmount(
      _fuzzInputs.amount
    ).withRecipient(_fuzzInputs.recipient);
    // create consideration array
    _considerationItemArray =
      SeaportArrays.ConsiderationItems(erc721ConsiderationItem, nativeConsiderationItem, erc20ConsiderationItemOne);
  }

  function _buildOrderComponents(
    FuzzInputs memory _fuzzInputs,
    OfferItem[] memory offerItemArray,
    ConsiderationItem[] memory considerationItemArray
  ) internal view returns (OrderComponents memory _orderComponents) {
    // Create the offer and consideration item arrays.
    OfferItem[] memory _offerItemArray = offerItemArray;
    ConsiderationItem[] memory _considerationItemArray = considerationItemArray;

    // Build the OrderComponents for the prime offerer's order.
    _orderComponents = OrderComponentsLib.fromDefault(SINGLE_721_Order).withOffer(_offerItemArray).withConsideration(
      _considerationItemArray
    ).withZone(address(1)).withOfferer(_fuzzInputs.offerer).withZone(address(2)).withOrderType(
      OrderType.FULL_RESTRICTED
    ).withZoneHash(_fuzzInputs.zoneHash);
  }

  function getZoneParameters(
    AdvancedOrder memory advancedOrder,
    address fulfiller,
    CriteriaResolver[] memory criteriaResolvers
  ) internal view returns (ZoneParameters memory zoneParameters) {
    // Get orderParameters from advancedOrder
    OrderParameters memory orderParameters = advancedOrder.parameters;

    // crate arbitrary orderHash
    bytes32 orderHash = keccak256(abi.encode(advancedOrder));

    (SpentItem[] memory spentItems, ReceivedItem[] memory receivedItems) =
      orderParameters.getSpentAndReceivedItems(advancedOrder.numerator, advancedOrder.denominator, 0, criteriaResolvers);
    // Store orderHash in orderHashes array to pass into zoneParameters
    bytes32[] memory orderHashes = new bytes32[](1);
    orderHashes[0] = orderHash;

    // Create ZoneParameters and add to zoneParameters array
    zoneParameters = ZoneParameters({
      orderHash: orderHash,
      fulfiller: fulfiller,
      offerer: orderParameters.offerer,
      offer: spentItems,
      consideration: receivedItems,
      extraData: advancedOrder.extraData,
      orderHashes: orderHashes,
      startTime: orderParameters.startTime,
      endTime: orderParameters.endTime,
      zoneHash: orderParameters.zoneHash
    });
  }
}
