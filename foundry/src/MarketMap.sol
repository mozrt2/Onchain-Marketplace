// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// Maps NFTs for sale.

import "./MarketInterface.sol";

struct UniqueOrderParameters {
    address offerer; 
    uint256 amount;
    uint256 startTime;
    uint256 endTime; 
    uint256 salt; 
    bytes signature;
}

contract MarketMap {

    address immutable seaportAddress;
    ISeaport immutable seaport;
    ISeaportValidator immutable seaportValidator;
    bytes32 immutable conduitKey;

    constructor (
        address _seaportAddress, 
        address _seaportValidatorAddress, 
        bytes32 _conduitKey
        ) {
        seaportAddress = _seaportAddress;
        seaport = ISeaport(_seaportAddress);
        seaportValidator = ISeaportValidator(_seaportValidatorAddress);
        conduitKey = _conduitKey;
    }

    mapping(address => mapping(uint256 => UniqueOrderParameters)) public orders;
    mapping(address => uint256[]) private tokenIdsWithOrders;
    mapping(address => mapping(uint256 => uint256)) private tokenIdToIndex;

    function sell(
        Order memory order 
    ) public {
        uint16[] memory errors = seaportValidator.validateOfferItems(order.parameters).errors;
        require(errors.length == 0 || errors[0] == 304, "Invalid order");

        address approvedAddress = IERC721(order.parameters.offer[0].token).getApproved(order.parameters.offer[0].identifierOrCriteria);
        require(approvedAddress == seaportAddress, "Seaport not approved to transfer token");

        address token = order.parameters.offer[0].token;
        uint256 tokenId = order.parameters.offer[0].identifierOrCriteria;

        UniqueOrderParameters memory uniqueOrderParameters = UniqueOrderParameters({
            offerer: order.parameters.offerer,
            amount: order.parameters.consideration[0].startAmount,
            startTime: order.parameters.startTime,
            endTime: order.parameters.endTime,
            salt: order.parameters.salt,
            signature: order.signature
        });

        orders[token][tokenId] = uniqueOrderParameters;
        addTokenId(token, tokenId);
    }
 
    function buy(
        address token,
        uint256 tokenId,
        address recipient
    ) public payable {
        AdvancedOrder memory advancedOrder = composeOrder(token, tokenId);
        CriteriaResolver[] memory emptyCriteriaResolver = new CriteriaResolver[](0);
        bool fulfilled = seaport.fulfillAdvancedOrder{value: msg.value}(advancedOrder, emptyCriteriaResolver, conduitKey, recipient);

        if (fulfilled) {
            delete orders[token][tokenId]; 
            removeTokenId(token, tokenId);
        } else {
            revert("Order not fulfilled");
        }
    }

    function getOrders(
        address token
    ) public view returns (uint256[] memory) {
        return tokenIdsWithOrders[token];
    }

    function cancelOrder(
        address token,
        uint256 tokenId
    ) public {
        OrderParameters memory orderParameters = composeOrder(token, tokenId).parameters;
        address offerer = orderParameters.offerer;
        require(offerer == msg.sender, "Only seller can cancel order");
        uint256 counter = seaport.getCounter(offerer);
        OrderComponents[] memory orderComponents = new OrderComponents[](1);
        orderComponents[0] = OrderComponents({
            offerer: offerer,
            zone: orderParameters.zone,
            offer: orderParameters.offer,
            consideration: orderParameters.consideration,
            orderType: orderParameters.orderType,
            startTime: orderParameters.startTime,
            endTime: orderParameters.endTime,
            zoneHash: orderParameters.zoneHash,
            salt: orderParameters.salt,
            conduitKey: orderParameters.conduitKey,
            counter: counter
        });

        seaport.cancel(orderComponents);
        delete orders[token][tokenId];
        removeTokenId(token, tokenId);
    }

    function composeOrder(
        address token,
        uint256 tokenId
    ) internal view returns (AdvancedOrder memory) {
        UniqueOrderParameters memory uniqueOrderParameters = orders[token][tokenId];

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: token,
            identifierOrCriteria: tokenId,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: uniqueOrderParameters.amount,
            endAmount: uniqueOrderParameters.amount,
            recipient: payable(uniqueOrderParameters.offerer)
        });

        AdvancedOrder memory advancedOrder = AdvancedOrder({
            parameters: OrderParameters({
                offerer: uniqueOrderParameters.offerer,
                zone: address(this),
                offer: offer,
                consideration: consideration,
                orderType: OrderType.FULL_OPEN,
                startTime: uniqueOrderParameters.startTime,
                endTime: uniqueOrderParameters.endTime,
                zoneHash: bytes32(0),
                salt: uniqueOrderParameters.salt,
                conduitKey: bytes32(0),
                totalOriginalConsiderationItems: 1
            }),
            numerator: 1,
            denominator: 1,
            signature: uniqueOrderParameters.signature,
            extraData: bytes("")
        });

        return advancedOrder;
    } 

    function addTokenId(address token, uint256 tokenId) internal {
        if(tokenIdToIndex[token][tokenId] != 0) {
            removeTokenId(token, tokenId);
        }
        tokenIdToIndex[token][tokenId] = tokenIdsWithOrders[token].length + 1;
        tokenIdsWithOrders[token].push(tokenId);
    }

    function removeTokenId(address token, uint256 tokenId) internal {
        uint256 index = tokenIdToIndex[token][tokenId] - 1;
        uint256 lastTokenId = tokenIdsWithOrders[token][tokenIdsWithOrders[token].length - 1];

        tokenIdsWithOrders[token][index] = lastTokenId;
        tokenIdToIndex[token][lastTokenId] = index + 1;
        tokenIdsWithOrders[token].pop();

        delete tokenIdToIndex[token][tokenId];
    }
}