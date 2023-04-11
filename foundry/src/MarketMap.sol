// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MarketInterface.sol";

/// @title MarketMap
/// @author mozrt (mozrt.eth)
/// @notice This contract stores and manages simple Seaport buy and sell orders onchain.

contract MarketMap {

    address immutable seaportAddress;
    ISeaport immutable seaport;
    address immutable openseaAddress;
    uint256 immutable openseaFee;
    bytes32 immutable openseaConduitKey;

    /// @notice Creates a new MarketMap contract.
    /// @param _seaportAddress The address of the Seaport contract.
    /// @param _openseaAddress The address of the Opensea contract.
    /// @param _openseaFee The fee charged by Opensea for a sale of 1 ETH.
    /// @param _openseaConduitKey The key for the Opensea Conduit.
    constructor (
        address _seaportAddress, 
        address _openseaAddress,
        uint256 _openseaFee,
        bytes32 _openseaConduitKey
        ) {
        seaportAddress = _seaportAddress;
        seaport = ISeaport(_seaportAddress);
        openseaAddress = _openseaAddress;
        openseaFee = _openseaFee;
        openseaConduitKey = _openseaConduitKey;
    }

    /// @notice Mapping to store unique order parameters for each token ID of a given address.
    mapping(address => mapping(uint256 => UniqueOrderParameters)) public orders;

    /// @notice Mapping to store additional recipients (e.g. royalty recipients) for each token ID of a given address.
    mapping(address => mapping(uint256 => mapping(uint8 => AdditionalRecipient))) public additionalRecipients;

    /// @notice Mapping to store a list of all token IDs with orders for each NFT collection.
    mapping(address => uint256[]) private tokenIdsWithOrders;

    /// @notice Mapping to store the index of each token ID in tokenIdsWithOrders.
    mapping(address => mapping(uint256 => uint256)) private tokenIdToIndex;

    /// @notice Creates a sell order after ensuring that it is in the valid format and the token is approved for Seaport.
    /// @param order The order parameters in Seaport's format.
    /// @param openseaSignature Optional signature from Opensea, if provided it will submit an order to Opensea.
    function sell(Order memory order, bytes memory openseaSignature) public {
        validateOrderParameters(order);

        Order[] memory orderList = processOpenseaSignature(order, openseaSignature);

        bool validated = seaport.validate(orderList);
        require(validated == true, "Invalid order");

        storeOrderAndRecipients(order);
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

        bool fulfilled = seaport.fulfillAdvancedOrder{value: msg.value}(advancedOrder, emptyCriteriaResolver, bytes32(0), recipient);

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

        uint256 considerations;
        uint8 i = 1;	
        while (additionalRecipients[token][tokenId][i].amount > 0) {
            considerations++;
            i++;
            delete additionalRecipients[token][tokenId][i];
        }
        
        removeTokenId(token, tokenId);
    }

    /// @notice Retrieves the status of a given order.
    /// @param token The address of the token involved in the order.
    /// @param tokenId The token ID involved in the order.
    /// @return isActive A boolean value indicating whether the order is active or not.
    function getOrderStatus(address token, uint256 tokenId) public view returns (bool isActive) {
        AdvancedOrder memory advancedOrder = composeOrder(token, tokenId);
        OrderComponents memory orderComponents = OrderComponents({
            offerer: advancedOrder.parameters.offerer,
            zone: advancedOrder.parameters.zone,
            offer: advancedOrder.parameters.offer,
            consideration: advancedOrder.parameters.consideration,
            orderType: advancedOrder.parameters.orderType,
            startTime: advancedOrder.parameters.startTime,
            endTime: advancedOrder.parameters.endTime,
            zoneHash: advancedOrder.parameters.zoneHash,
            salt: advancedOrder.parameters.salt,
            conduitKey: advancedOrder.parameters.conduitKey,
            counter: seaport.getCounter(advancedOrder.parameters.offerer)
        });
        bytes32 orderHash = seaport.getOrderHash(orderComponents);
        (isActive,,,) = seaport.getOrderStatus(orderHash);
        return isActive;
    }

    /// @notice Pre-validates the order parameters to ensure they can be stored without issues.
    /// @param order The order parameters in Seaport's format.
    function validateOrderParameters(Order memory order) internal view {
        uint256 amount = order.parameters.consideration[0].startAmount;
        require(amount % 1e3 == 0 && amount < 1.84 * 1e22, "Wei amount cannot have any digits other than 0 for its first 3 digits and cannot exceed 18,400 ETH");

        uint256 endTime = order.parameters.endTime;
        require(endTime < 4.2 * 1e9, "End time must be smaller than 4.2 billion");

        uint256 salt = order.parameters.salt;
        require(salt < 65000, "Salt must be less than 65,000");

        address approvedAddress = IERC721(order.parameters.offer[0].token).getApproved(order.parameters.offer[0].identifierOrCriteria);
        require(approvedAddress == seaportAddress, "Seaport not approved to transfer token");
    }

    /// @notice Processes and validates the optional Opensea signature, if provided.
    /// @param order The order parameters in Seaport's format.
    /// @param openseaSignature The Opensea signature (optional).
    /// @return orderList An array containing the original order and the Opensea order (if provided).
    function processOpenseaSignature(Order memory order, bytes memory openseaSignature) internal view returns (Order[] memory orderList) {
        if (openseaSignature.length > 0) {
            Order memory openseaOrder = composeOpenseaOrder(order, openseaSignature);
            orderList = new Order[](2);
            orderList[0] = order;
            orderList[1] = openseaOrder;
        } else {
            orderList = new Order[](1);
            orderList[0] = order;
        }
        return orderList;
    }

    /// @notice Stores the order and any additional recipients in the contract and updates the relevant mappings.
    /// @param order The order parameters in Seaport's format.
    function storeOrderAndRecipients(Order memory order) internal {
        address token = order.parameters.offer[0].token;
        uint256 tokenId = order.parameters.offer[0].identifierOrCriteria;

        (bytes1 v, bytes32 r, bytes32 s) = extractSignatureComponents(order.signature);

        uint8 considerations = uint8(order.parameters.consideration.length);
        storeAdditionalRecipients(order, considerations);

        UniqueOrderParameters memory uniqueOrderParameters = createUniqueOrderParameters(order, v, r, s);
        orders[token][tokenId] = uniqueOrderParameters;

        addTokenId(token, tokenId);
    }

    /// @notice Extracts the v, r, and s components from the signature.
    /// @param signature The order signature as bytes.
    /// @return v The 'v' component of the signature.
    /// @return r The 'r' component of the signature.
    /// @return s The 's' component of the signature.
    function extractSignatureComponents( 
        bytes memory signature 
    ) internal pure returns (
        bytes1 v, bytes32 r, bytes32 s
    ) {
        assembly {
            v := mload(add(signature, 0x20))
            r := mload(add(signature, 0x21))
            s := mload(add(signature, 0x41))
        }
    }

    /// @notice Creates a UniqueOrderParameters struct from the given order and its signature components.
    /// @param order The order data.
    /// @param v The 'v' component of the order signature.
    /// @param r The 'r' component of the order signature.
    /// @param s The 's' component of the order signature.
    /// @return A UniqueOrderParameters struct containing a condensed representation of the order data and its signature components.
    function createUniqueOrderParameters(
        Order memory order,
        bytes1 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (
        UniqueOrderParameters memory
    ) {
        return UniqueOrderParameters({
            amount: uint64(order.parameters.consideration[0].startAmount / 1e3),
            startTime: uint32(order.parameters.startTime),
            endTime: uint32(order.parameters.endTime),
            salt: uint16(order.parameters.salt),
            vSignature: v,
            rSignature: r,
            sSignature: s
        });
    }

    /// @notice Stores additional recipients for an order, if any, in the additionalRecipients mapping.
    /// @param order The order data containing the additional recipient information.
    /// @param considerations The number of considerations (recipients) in the order.
    function storeAdditionalRecipients(
        Order memory order,
        uint8 considerations
    ) internal {
        if (considerations > 1) {
            address token = order.parameters.offer[0].token;
            uint256 tokenId = order.parameters.offer[0].identifierOrCriteria;
            for (uint8 i = 1; i < considerations; i++) {
                AdditionalRecipient memory recipient = AdditionalRecipient({
                    recipient: order.parameters.consideration[i].recipient,
                    amount: uint64(order.parameters.consideration[i].startAmount / 1e3)
                });
                additionalRecipients[token][tokenId][i] = recipient;
            }
        }
    }

    /// @notice Composes an Opensea order based on the provided order and signature.
    /// @param order The base order, not including Opensea as a recipient.
    /// @param openseaSignature The signature of the Opensea order.
    /// @return openseaOrder The composed Opensea order.
    function composeOpenseaOrder(
        Order memory order,
        bytes memory openseaSignature
    ) internal view returns (
        Order memory openseaOrder
    ) {
        openseaOrder.parameters.offerer = order.parameters.offerer;
        openseaOrder.parameters.zone = address(0);
        openseaOrder.parameters.offer = order.parameters.offer;
        openseaOrder.parameters.orderType = order.parameters.orderType;
        openseaOrder.parameters.startTime = order.parameters.startTime;
        openseaOrder.parameters.endTime = order.parameters.endTime;
        openseaOrder.parameters.zoneHash = order.parameters.zoneHash;
        openseaOrder.parameters.salt = order.parameters.salt;
        openseaOrder.parameters.conduitKey = openseaConduitKey;
        openseaOrder.signature = openseaSignature;

        uint256 considerations = order.parameters.consideration.length;

        uint256 amount;
        if (considerations == 1) {
            amount = order.parameters.consideration[0].startAmount*openseaFee/1e18;
        } else {
            amount = (order.parameters.consideration[0].startAmount+order.parameters.consideration[1].startAmount)*openseaFee/1e18;
        }

        ConsiderationItem[] memory openseaConsideration = new ConsiderationItem[](considerations + 1);
        openseaConsideration[0] = order.parameters.consideration[0];
        openseaConsideration[1] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: amount,
            endAmount: amount,
            recipient: payable(openseaAddress)
        });
        if (considerations == 2) {
            openseaConsideration[2] = order.parameters.consideration[1];
        }
        openseaOrder.parameters.consideration = openseaConsideration;
        openseaOrder.parameters.totalOriginalConsiderationItems = order.parameters.totalOriginalConsiderationItems + 1;

        return openseaOrder;
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
        uint256 amount = uint256(uniqueOrderParameters.amount)*1e3;
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: token,
            identifierOrCriteria: tokenId,
            startAmount: 1,
            endAmount: 1
        });

        uint256 considerations;
        uint8 i = 1;	
        while (additionalRecipients[token][tokenId][i].amount > 0) {
            considerations++;
            i++;
        }

        ConsiderationItem[] memory consideration = new ConsiderationItem[](i);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: amount,
            endAmount: amount,
            recipient: payable(offerer)
        });

        if (i > 1) {
            for (uint8 j = 1; j < i; j++) {
                AdditionalRecipient memory recipient = additionalRecipients[token][tokenId][j];
                uint256 recipientAmount = uint256(recipient.amount)*1e3;
                consideration[j] = ConsiderationItem({
                    itemType: ItemType.NATIVE,
                    token: address(0),
                    identifierOrCriteria: 0,
                    startAmount: recipientAmount,
                    endAmount: recipientAmount,
                    recipient: payable(recipient.recipient)
                });
            }
        }

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
                totalOriginalConsiderationItems: uint256(i)
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