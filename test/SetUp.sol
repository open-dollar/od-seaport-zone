// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {
  ERC20Interface, ERC721Interface, ERC1155Interface
} from 'seaport-types/src/interfaces/AbridgedTokenInterfaces.sol';

import {
  AdvancedOrder,
  BasicOrderParameters,
  CriteriaResolver,
  Execution,
  Fulfillment,
  FulfillmentComponent,
  OrderParameters
} from 'seaport-sol/src/SeaportStructs.sol';

import {AdvancedOrderLib, BasicOrderParametersLib, MatchComponent} from 'seaport-sol/src/SeaportSol.sol';

import {ERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {ItemType} from 'seaport-types/src/lib/ConsiderationEnums.sol';

import {ContractOffererInterface} from 'seaport-types/src/interfaces/ContractOffererInterface.sol';
import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

import {ZoneInterface} from 'seaport-types/src/interfaces/ZoneInterface.sol';

import {BaseTest} from 'seaport-sol/test/BaseTest.sol';
import {ODNFVZone} from '../src/contracts/ODNFVZone.sol';
import {ODNFVZoneInterface} from '../src/interfaces/ODNFVZoneInterface.sol';
import {ODNFVZoneControllerInterface} from '../src/interfaces/ODNFVZoneControllerInterface.sol';
import {ODNFVZoneController} from '../src/contracts/ODNFVZoneController.sol';
import {Seaport as CoreSeaport} from 'seaport-core/Seaport.sol';

import 'forge-std/console2.sol';

/// order builder

import {
  OrderParameters,
  OrderComponents,
  Order,
  BasicOrderParameters,
  SpentItem,
  AdditionalRecipient,
  OfferItem,
  ItemType,
  ConsiderationItem,
  Fulfillment,
  FulfillmentComponent,
  AdvancedOrder
} from 'seaport-types/src/lib/ConsiderationStructs.sol';

import {OrderType, BasicOrderType} from 'seaport-types/src/lib/ConsiderationEnums.sol';

import {ConsiderationInterface} from 'seaport-types/src/interfaces/ConsiderationInterface.sol';

contract SetUp is BaseTest {
  using BasicOrderParametersLib for BasicOrderParameters;
  using AdvancedOrderLib for AdvancedOrder;
  using AdvancedOrderLib for AdvancedOrder[];

  address deployer = address(0xdeadce11);
  address payable public seaportMainnetAddress = payable(address(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC)); //seaport 1.5 on arb mainnet
  CoreSeaport public seaport;
  ODNFVZoneInterface public zone;
  ODNFVZoneController public zoneController;

  function setUp() public virtual override {
    super.setUp();
    //create arb mainnet fork;
    vm.createSelectFork(vm.envString('ARB_MAINNET_RPC'));
    vm.deal(deployer, 1000 ether);
    vm.startPrank(deployer);
    seaport = CoreSeaport(seaportMainnetAddress);
    zoneController = new ODNFVZoneController(deployer);
    zone = ODNFVZoneInterface(zoneController.createZone(keccak256(abi.encode('salt'))));
  }

  bytes23 conduitKeyOne;
  uint256 internal globalSalt;
  address test721_1 = address(1);
  FulfillmentComponent[] public offerComponents;
  FulfillmentComponent[] public considerationComponents;

  Fulfillment fulfillment;
  Fulfillment[] fulfillments;

  FulfillmentComponent public fulfillmentComponent;
  FulfillmentComponent[] public fulfillmentComponents;

  FulfillmentComponent[][] offerComponentsArray;
  FulfillmentComponent[][] considerationComponentsArray;

  OrderParameters public baseOrderParameters;
  OrderComponents public baseOrderComponents;

  ///////////////////// Item Addr
  OfferItem public offerItem;
  ConsiderationItem public considerationItem;
  OfferItem[] public offerItems;
  ConsiderationItem[] public considerationItems;
  SpentItem[] public minimumReceived;
  SpentItem[] public maximumSpent;

  function setConsiderationItems(ConsiderationItem[] storage dest, ConsiderationItem[] memory src) internal {
    while (dest.length != 0) {
      dest.pop();
    }
    for (uint256 i = 0; i < src.length; ++i) {
      dest.push(src[i]);
    }
  }

  function setOfferItems(OfferItem[] storage dest, OfferItem[] memory src) internal {
    while (dest.length != 0) {
      dest.pop();
    }
    for (uint256 i = 0; i < src.length; ++i) {
      dest.push(src[i]);
    }
  }

  ///@dev reset the offer items array
  function resetOfferItems() internal {
    delete offerItems;
  }

  ///@dev Add an offer item to the offer items array
  function addOfferItem(OfferItem memory _offerItem) internal {
    offerItems.push(_offerItem);
  }

  ///@dev Construct and an offer item to the offer items array
  function addOfferItem(address token, uint256 identifier, uint256 startAmount, uint256 endAmount) internal {
    offerItem.itemType = ItemType.ERC721;
    offerItem.token = token;
    offerItem.identifierOrCriteria = identifier;
    offerItem.startAmount = startAmount;
    offerItem.endAmount = endAmount;
    addOfferItem(offerItem);
    delete offerItem;
  }

  function addOfferItem(address token, uint256 identifier) internal {
    addErc721OfferItem(token, identifier);
  }

  function addErc721OfferItem(address token, uint256 identifier) internal {
    addOfferItem(token, identifier, 1, 1);
  }

  ///@dev reset the considerationItems array
  function resetConsiderationItems() internal {
    delete considerationItems;
  }

  ///@dev construct a considerationItem and add it to the considerationItems array
  function addConsiderationItem(
    address payable recipient,
    // ItemType itemType,
    address token,
    uint256 identifier,
    uint256 startAmount,
    uint256 endAmount
  ) internal {
    considerationItem.itemType = ItemType.ERC721;
    considerationItem.token = token;
    considerationItem.identifierOrCriteria = identifier;
    considerationItem.startAmount = startAmount;
    considerationItem.endAmount = endAmount;
    considerationItem.recipient = recipient;
    addConsiderationItem(considerationItem);
    delete considerationItem;
  }

  function addConsiderationItem(address payable recipient, uint256 identifier) internal {
    addErc721ConsiderationItem(recipient, identifier);
  }

  ///@dev add a considerationItem to the considerationItems array
  function addConsiderationItem(ConsiderationItem memory _considerationItem) internal {
    considerationItems.push(_considerationItem);
  }

  function addErc721ConsiderationItem(address payable recipient, uint256 tokenId) internal {
    addConsiderationItem(recipient, address(test721_1), tokenId, 1, 1);
  }

  function toSpentItem(OfferItem memory _offerItem) internal pure returns (SpentItem memory) {
    return SpentItem({
      itemType: _offerItem.itemType,
      token: _offerItem.token,
      identifier: _offerItem.identifierOrCriteria,
      amount: _offerItem.startAmount
    });
  }

  function toSpentItem(ConsiderationItem memory _considerationItem) internal pure returns (SpentItem memory) {
    return SpentItem({
      itemType: _considerationItem.itemType,
      token: _considerationItem.token,
      identifier: _considerationItem.identifierOrCriteria,
      amount: _considerationItem.startAmount
    });
  }

  function toSpentItems(OfferItem[] memory _offerItems) internal pure returns (SpentItem[] memory) {
    SpentItem[] memory spentItems = new SpentItem[](_offerItems.length);
    for (uint256 i; i < _offerItems.length; ++i) {
      spentItems[i] = toSpentItem(_offerItems[i]);
    }
    return spentItems;
  }

  function toSpentItems(ConsiderationItem[] memory _considerationItems) internal pure returns (SpentItem[] memory) {
    SpentItem[] memory spentItems = new SpentItem[](_considerationItems.length);
    for (uint256 i; i < _considerationItems.length; ++i) {
      spentItems[i] = toSpentItem(_considerationItems[i]);
    }
    return spentItems;
  }

  function toHashedLeaves(uint256[] memory identifiers) internal pure returns (bytes32[] memory) {
    bytes32[] memory hashedLeaves = new bytes32[](identifiers.length);
    for (uint256 i; i < identifiers.length; ++i) {
      hashedLeaves[i] = keccak256(abi.encode(identifiers[i]));
    }
    return hashedLeaves;
  }

  function toAdvancedOrder(Order memory order) internal pure returns (AdvancedOrder memory) {
    return AdvancedOrder({
      parameters: order.parameters,
      numerator: 1,
      denominator: 1,
      signature: order.signature,
      extraData: ''
    });
  }

  function toAdvancedOrder(Order memory order, bytes memory extraData) internal pure returns (AdvancedOrder memory) {
    return AdvancedOrder({
      parameters: order.parameters,
      numerator: 1,
      denominator: 1,
      signature: order.signature,
      extraData: extraData
    });
  }

  function createMirrorOrderAndFulfillments(
    ConsiderationInterface _consideration,
    OrderParameters memory order1
  ) internal returns (Order memory, Fulfillment[] memory) {
    Order memory mirrorOrder = createSignedMirrorOrder(_consideration, order1, 'mirror offerer');
    return (mirrorOrder, createFulfillmentsFromMirrorOrders(order1, mirrorOrder.parameters));
  }

  function createFulfillmentsFromMirrorOrders(
    OrderParameters memory order1,
    OrderParameters memory order2
  ) internal returns (Fulfillment[] memory) {
    delete fulfillments;
    for (uint256 i; i < order1.offer.length; ++i) {
      createFulfillmentFromComponentsAndAddToFulfillments({
        _offer: FulfillmentComponent({orderIndex: 0, itemIndex: i}),
        _consideration: FulfillmentComponent({orderIndex: 1, itemIndex: i})
      });
    }
    for (uint256 i; i < order2.offer.length; ++i) {
      createFulfillmentFromComponentsAndAddToFulfillments({
        _offer: FulfillmentComponent({orderIndex: 1, itemIndex: i}),
        _consideration: FulfillmentComponent({orderIndex: 0, itemIndex: i})
      });
    }

    return fulfillments;
  }

  function createFulfillments(OrderParameters[] memory orders)
    internal
    returns (FulfillmentComponent[][] memory, FulfillmentComponent[][] memory)
  {
    delete offerComponentsArray;
    delete considerationComponentsArray;
    for (uint256 i; i < orders.length; ++i) {
      addFulfillmentsForOrderParams(orders[i], i);
    }
    return (offerComponentsArray, considerationComponentsArray);
  }

  function addFulfillmentsForOrderParams(OrderParameters memory params, uint256 orderIndex) internal {
    // create individual fulfillments for each offerItem
    for (uint256 i; i < params.offer.length; ++i) {
      addSingleFulfillmentComponentsTo({
        component: FulfillmentComponent({orderIndex: orderIndex, itemIndex: i}),
        target: offerComponentsArray
      });
    }
    // create individual fulfillments for each considerationItem
    for (uint256 i; i < params.consideration.length; ++i) {
      addSingleFulfillmentComponentsTo({
        component: FulfillmentComponent({orderIndex: orderIndex, itemIndex: i}),
        target: considerationComponentsArray
      });
    }
  }

  function addSingleFulfillmentComponentsTo(
    FulfillmentComponent memory component,
    FulfillmentComponent[][] storage target
  ) internal {
    delete fulfillmentComponents;
    fulfillmentComponents.push(component);
    target.push(fulfillmentComponents);
  }

  function createFulfillmentFromComponentsAndAddToFulfillments(
    FulfillmentComponent memory _offer,
    FulfillmentComponent memory _consideration
  ) internal {
    delete offerComponents;
    delete considerationComponents;
    offerComponents.push(_offer);
    considerationComponents.push(_consideration);
    fulfillment.offerComponents = offerComponents;
    fulfillment.considerationComponents = considerationComponents;
    fulfillments.push(fulfillment);
  }

  function createSignedOrder(
    ConsiderationInterface _consideration,
    string memory offerer
  ) internal returns (Order memory) {
    (address offererAddr, uint256 pkey) = makeAddrAndKey(offerer);
    configureOrderParameters(offererAddr);
    configureOrderComponents(_consideration);
    bytes32 orderHash = _consideration.getOrderHash(baseOrderComponents);

    Order memory order = Order({parameters: baseOrderParameters, signature: signOrder(_consideration, pkey, orderHash)});
    delete offerItems;
    delete considerationItems;
    delete baseOrderComponents;
    delete baseOrderParameters;
    return order;
  }

  function createSignedMirrorOrder(
    ConsiderationInterface _consideration,
    OrderParameters memory originalParameters,
    string memory mirrorOfferer
  ) internal returns (Order memory) {
    (address offerer, uint256 pkey) = makeAddrAndKey(mirrorOfferer);

    (OfferItem[] memory newOffer, ConsiderationItem[] memory newConsideration) =
      mirrorOfferAndConsideration(originalParameters.offer, originalParameters.consideration, offerer);
    baseOrderParameters.offerer = offerer;
    baseOrderParameters.zone = originalParameters.zone;
    setOfferItems(baseOrderParameters.offer, newOffer);
    setConsiderationItems(baseOrderParameters.consideration, newConsideration);
    baseOrderParameters.orderType = originalParameters.orderType;
    baseOrderParameters.startTime = originalParameters.startTime;
    baseOrderParameters.endTime = originalParameters.endTime;
    baseOrderParameters.zoneHash = originalParameters.zoneHash;
    baseOrderParameters.salt = globalSalt++;
    baseOrderParameters.conduitKey = originalParameters.conduitKey;
    baseOrderParameters.totalOriginalConsiderationItems = originalParameters.offer.length;

    configureOrderComponents(_consideration);
    bytes32 orderHash = _consideration.getOrderHash(baseOrderComponents);
    Order memory order = Order({parameters: baseOrderParameters, signature: signOrder(_consideration, pkey, orderHash)});

    delete offerItems;
    delete considerationItems;
    delete baseOrderComponents;
    delete baseOrderParameters;
    return order;
  }

  function mirrorOfferAndConsideration(
    OfferItem[] memory _offer,
    ConsiderationItem[] memory _consideration,
    address mirrorOfferer
  ) internal pure returns (OfferItem[] memory newOffer, ConsiderationItem[] memory newConsideration) {
    return (mirrorConsiderationItems(_consideration), mirrorOfferItems(_offer, payable(mirrorOfferer)));
  }

  function mirrorOfferItems(
    OfferItem[] memory _offers,
    address payable recipient
  ) internal pure returns (ConsiderationItem[] memory) {
    ConsiderationItem[] memory newConsideration = new ConsiderationItem[](_offers.length);
    for (uint256 i = 0; i < _offers.length; i++) {
      newConsideration[i] = mirrorOfferItem(_offers[i], recipient);
    }
    return newConsideration;
  }

  function mirrorOfferItem(
    OfferItem memory _offer,
    address payable recipient
  ) internal pure returns (ConsiderationItem memory) {
    return ConsiderationItem({
      itemType: _offer.itemType,
      token: _offer.token,
      identifierOrCriteria: _offer.identifierOrCriteria,
      startAmount: _offer.startAmount,
      endAmount: _offer.endAmount,
      recipient: recipient
    });
  }

  function mirrorConsiderationItems(ConsiderationItem[] memory _considerations)
    internal
    pure
    returns (OfferItem[] memory)
  {
    OfferItem[] memory newOffer = new OfferItem[](_considerations.length);
    for (uint256 i = 0; i < _considerations.length; i++) {
      newOffer[i] = mirrorConsiderationItem(_considerations[i]);
    }
    return newOffer;
  }

  function mirrorConsiderationItem(ConsiderationItem memory _consideration) internal pure returns (OfferItem memory) {
    return OfferItem({
      itemType: _consideration.itemType,
      token: _consideration.token,
      identifierOrCriteria: _consideration.identifierOrCriteria,
      startAmount: _consideration.startAmount,
      endAmount: _consideration.endAmount
    });
  }

  function configureOrderParameters(address offerer) internal {
    configureOrderParameters(offerer, address(0), bytes32(0));
  }

  function configureOrderParameters(address offerer, OrderType orderType) internal {
    configureOrderParameters(offerer, address(0), bytes32(0));
    baseOrderParameters.orderType = orderType;
  }

  function configureOrderParameters(address offerer, address zone, bytes32 zoneHash) internal {
    _configureOrderParameters(offerer, zone, zoneHash, globalSalt++, false);
  }

  function _configureOrderParameters(
    address offerer,
    address zone,
    bytes32 zoneHash,
    uint256 salt,
    bool useConduit
  ) internal {
    _configureOrderParameters(offerer, zone, zoneHash, salt, OrderType.FULL_OPEN, useConduit);
  }

  function _configureOrderParameters(
    address offerer,
    address zone,
    bytes32 zoneHash,
    uint256 salt,
    OrderType orderType,
    bool useConduit
  ) internal {
    bytes32 conduitKey = useConduit ? conduitKeyOne : bytes32(0);
    baseOrderParameters.offerer = offerer;
    baseOrderParameters.zone = zone;
    baseOrderParameters.offer = offerItems;
    baseOrderParameters.consideration = considerationItems;
    baseOrderParameters.orderType = orderType;
    baseOrderParameters.startTime = block.timestamp;
    baseOrderParameters.endTime = block.timestamp + 1;
    baseOrderParameters.zoneHash = zoneHash;
    baseOrderParameters.salt = salt;
    baseOrderParameters.conduitKey = conduitKey;
    baseOrderParameters.totalOriginalConsiderationItems = considerationItems.length;
  }

  function _configureOrderParametersSetEndTime(
    address offerer,
    address zone,
    uint256 endTime,
    bytes32 zoneHash,
    uint256 salt,
    bool useConduit
  ) internal {
    _configureOrderParameters(offerer, zone, zoneHash, salt, useConduit);
    baseOrderParameters.endTime = endTime;
  }

  function configureOrderComponents(ConsiderationInterface _consideration) internal {
    configureOrderComponents(_consideration.getCounter(baseOrderParameters.offerer));
  }

  /**
   * @dev configures order components based on order parameters in storage and counter param
   */
  function configureOrderComponents(uint256 counter) internal {
    baseOrderComponents.offerer = baseOrderParameters.offerer;
    baseOrderComponents.zone = baseOrderParameters.zone;
    baseOrderComponents.offer = baseOrderParameters.offer;
    baseOrderComponents.consideration = baseOrderParameters.consideration;
    baseOrderComponents.orderType = baseOrderParameters.orderType;
    baseOrderComponents.startTime = baseOrderParameters.startTime;
    baseOrderComponents.endTime = baseOrderParameters.endTime;
    baseOrderComponents.zoneHash = baseOrderParameters.zoneHash;
    baseOrderComponents.salt = baseOrderParameters.salt;
    baseOrderComponents.conduitKey = baseOrderParameters.conduitKey;
    baseOrderComponents.counter = counter;
  }

  function toBasicOrderParameters(
    Order memory _order,
    BasicOrderType basicOrderType
  ) internal pure returns (BasicOrderParameters memory) {
    AdditionalRecipient[] memory additionalRecipients =
      new AdditionalRecipient[](_order.parameters.consideration.length - 1);
    for (uint256 i = 1; i < _order.parameters.consideration.length; i++) {
      additionalRecipients[i - 1] = AdditionalRecipient({
        recipient: _order.parameters.consideration[i].recipient,
        amount: _order.parameters.consideration[i].startAmount
      });
    }

    return BasicOrderParameters(
      _order.parameters.consideration[0].token,
      _order.parameters.consideration[0].identifierOrCriteria,
      _order.parameters.consideration[0].endAmount,
      payable(_order.parameters.offerer),
      _order.parameters.zone,
      _order.parameters.offer[0].token,
      _order.parameters.offer[0].identifierOrCriteria,
      _order.parameters.offer[0].endAmount,
      basicOrderType,
      _order.parameters.startTime,
      _order.parameters.endTime,
      _order.parameters.zoneHash,
      _order.parameters.salt,
      _order.parameters.conduitKey,
      _order.parameters.conduitKey,
      _order.parameters.totalOriginalConsiderationItems - 1,
      additionalRecipients,
      _order.signature
    );
  }

  function toBasicOrderParameters(
    OrderComponents memory _order,
    BasicOrderType basicOrderType,
    bytes memory signature
  ) internal pure returns (BasicOrderParameters memory) {
    return BasicOrderParameters(
      _order.consideration[0].token,
      _order.consideration[0].identifierOrCriteria,
      _order.consideration[0].endAmount,
      payable(_order.offerer),
      _order.zone,
      _order.offer[0].token,
      _order.offer[0].identifierOrCriteria,
      _order.offer[0].endAmount,
      basicOrderType,
      _order.startTime,
      _order.endTime,
      _order.zoneHash,
      _order.salt,
      _order.conduitKey,
      _order.conduitKey,
      0,
      new AdditionalRecipient[](0),
      signature
    );
  }

  function signOrder(
    ConsiderationInterface _consideration,
    uint256 _pkOfSigner,
    bytes32 _orderHash
  ) internal view returns (bytes memory) {
    (bytes32 r, bytes32 s, uint8 v) = getSignatureComponents(_consideration, _pkOfSigner, _orderHash);
    return abi.encodePacked(r, s, v);
  }

  function getSignatureComponents(
    ConsiderationInterface _consideration,
    uint256 _pkOfSigner,
    bytes32 _orderHash
  ) internal view returns (bytes32, bytes32, uint8) {
    (, bytes32 domainSeparator,) = _consideration.information();
    (uint8 v, bytes32 r, bytes32 s) =
      vm.sign(_pkOfSigner, keccak256(abi.encodePacked(bytes2(0x1901), domainSeparator, _orderHash)));
    return (r, s, v);
  }
}
