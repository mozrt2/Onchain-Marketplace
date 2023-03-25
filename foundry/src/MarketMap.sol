// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MarketInterface.sol";

/// @title MarketMap
/// @author mozrt (mozrt.eth)
/// @notice This contract stores and manages simple ERC721 (NFT) buy and sell orders for Seaport onchain.

struct UniqueOrderParameters {
    uint32 amount;
    uint32 startTime;
    uint32 endTime; 
    uint16 salt; 
    bytes1 vSignature;
    bytes32 rSignature;
    bytes32 sSignature;
}

contract MarketMap {

    address immutable seaportAddress;
    ISeaport immutable seaport;
    bytes32 immutable conduitKey;

    /// @notice Creates a new MarketMap contract.
    /// @param _seaportAddress The address of the Seaport contract.
    /// @param _conduitKey The key used for the conduit.
    constructor (
        address _seaportAddress, 
        bytes32 _conduitKey
        ) {
        seaportAddress = _seaportAddress;
        seaport = ISeaport(_seaportAddress);
        conduitKey = _conduitKey;
    }

    mapping(address => mapping(uint256 => UniqueOrderParameters)) public orders;
    mapping(address => uint256[]) private tokenIdsWithOrders;
    mapping(address => mapping(uint256 => uint256)) private tokenIdToIndex;

    /// @notice Creates a sell order after ensuring that it is in the valid format and the token is approved for Seaport.
    /// @param order The order parameters in Seaport's format.
    function sell(
        Order memory order 
    ) public {
        uint256 amount = order.parameters.consideration[0].startAmount;
        require(amount%1e13 == 0 && amount < 1e22, "Wei amount cannot have any digits other than 0 for its first 13 digits and cannot exceed 10,000 ETH");

        uint256 endTime = order.parameters.endTime;
        require(endTime < 4.2*1e9, "End time must be smaller than 4.2 billion");

        uint256 salt = order.parameters.salt;
        require(salt < 65000, "Salt must be less than 65,000");

        address approvedAddress = IERC721(order.parameters.offer[0].token).getApproved(order.parameters.offer[0].identifierOrCriteria);
        require(approvedAddress == seaportAddress, "Seaport not approved to transfer token");

        Order[] memory orderList = new Order[](1);
        orderList[0] = order;
        bool validated = seaport.validate(orderList);
        require(validated == true, "Invalid Order");

        bytes1 v;
        bytes32 r;
        bytes32 s;

        bytes memory signature = order.signature;

        assembly {
            v := mload(add(signature, 0x20))
            r := mload(add(signature, 0x21))
            s := mload(add(signature, 0x41))
        }

        UniqueOrderParameters memory uniqueOrderParameters = UniqueOrderParameters({
            amount: uint32(order.parameters.consideration[0].startAmount/1e13),
            startTime: uint32(order.parameters.startTime),
            endTime: uint32(order.parameters.endTime),
            salt: uint16(order.parameters.salt),
            vSignature: v,
            rSignature: r,
            sSignature: s
        });

        address token = order.parameters.offer[0].token;
        uint256 tokenId = order.parameters.offer[0].identifierOrCriteria;

        orders[token][tokenId] = uniqueOrderParameters;
        addTokenId(token, tokenId);
    }
 
    /// @notice Triggers the purchase of an NFT listed for sale on MarketMap.
    /// @param token The address of the NFT collection contract.
    /// @param tokenId The ID of the token.
    /// @param recipient The address of the recipient of the NFT.
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

    /// @notice Retrieves the token IDs of the listed orders for a given NFT collection.
    /// @param token The address of the NFT collection contract.
    /// @return A list of token IDs with active orders.
    function getOrders(
        address token
    ) public view returns (uint256[] memory) {
        return tokenIdsWithOrders[token];
    }

    /// @notice Allows a seller to cancel their order.
    /// @param token The address of the NFT collection contract.
    /// @param tokenId The ID of the token to be canceled.
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

        bool cancelled = seaport.cancel(orderComponents);
        require(cancelled == true, "Order couldn't be cancelled");

        delete orders[token][tokenId];
        removeTokenId(token, tokenId);
    }

    /// @notice Composes a Seaport AdvancedOrder object for a given order.
    /// @param token The address of the NFT collection.
    /// @param tokenId The ID of the token linked to the order.
    /// @return An AdvancedOrder object containing the order information.
    function composeOrder(
        address token,
        uint256 tokenId
    ) internal view returns (AdvancedOrder memory) {
        UniqueOrderParameters memory uniqueOrderParameters = orders[token][tokenId];
        address offerer = IERC721(token).ownerOf(tokenId);
        bytes memory signature = abi.encodePacked(
            uniqueOrderParameters.vSignature,
            uniqueOrderParameters.rSignature,
            uniqueOrderParameters.sSignature
        );
        uint256 amount = uint256(uniqueOrderParameters.amount)*1e13;
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
            startAmount: amount,
            endAmount: amount,
            recipient: payable(offerer)
        });

        AdvancedOrder memory advancedOrder = AdvancedOrder({
            parameters: OrderParameters({
                offerer: offerer,
                zone: address(this),
                offer: offer,
                consideration: consideration,
                orderType: OrderType.FULL_OPEN,
                startTime: uint256(uniqueOrderParameters.startTime),
                endTime: uint256(uniqueOrderParameters.endTime),
                zoneHash: bytes32(0),
                salt: uint256(uniqueOrderParameters.salt),
                conduitKey: bytes32(0),
                totalOriginalConsiderationItems: 1
            }),
            numerator: 1,
            denominator: 1,
            signature: signature,
            extraData: bytes("")
        });
        return advancedOrder;
    } 

    /// @notice Adds a token ID to the list of token IDs with active orders.
    /// @param token The address of the NFT collection contract.
    /// @param tokenId The ID of the token to be added.
    function addTokenId(address token, uint256 tokenId) internal {
        if(tokenIdToIndex[token][tokenId] != 0) {
            removeTokenId(token, tokenId);
        }
        tokenIdToIndex[token][tokenId] = tokenIdsWithOrders[token].length + 1;
        tokenIdsWithOrders[token].push(tokenId);
    }

    /// @notice Removes a token ID from the internal list of token IDs with active orders.
    /// @param token The address of the NFT collection contract.
    /// @param tokenId The ID of the token to be removed.
    function removeTokenId(address token, uint256 tokenId) internal {
        uint256 index = tokenIdToIndex[token][tokenId] - 1;
        uint256 lastTokenId = tokenIdsWithOrders[token][tokenIdsWithOrders[token].length - 1];

        tokenIdsWithOrders[token][index] = lastTokenId;
        tokenIdToIndex[token][lastTokenId] = index + 1;
        tokenIdsWithOrders[token].pop();

        delete tokenIdToIndex[token][tokenId];
    }
}