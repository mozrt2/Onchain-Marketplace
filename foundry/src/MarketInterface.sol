// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title MarketInterface
/// @author mozrt (mozrt.eth)
/// @notice Interface with Seaport for MarketMap. Refer to Seaport and SeaportValidator contracts for details on structs, enums, and functions below. 

struct OrderParameters {
    address offerer; 
    address zone; 
    OfferItem[] offer; 
    ConsiderationItem[] consideration; 
    OrderType orderType; 
    uint256 startTime;
    uint256 endTime; 
    bytes32 zoneHash; 
    uint256 salt; 
    bytes32 conduitKey; 
    uint256 totalOriginalConsiderationItems;
}

struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

struct Order {
    OrderParameters parameters;
    bytes signature;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

struct ErrorsAndWarnings {
    uint16[] errors;
    uint16[] warnings;
}

enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}

enum OrderType {
    FULL_OPEN,
    PARTIAL_OPEN,
    FULL_RESTRICTED,
    PARTIAL_RESTRICTED,
    CONTRACT
}

enum Side {
    OFFER,
    CONSIDERATION
}

interface ISeaport {
    function fulfillAdvancedOrder(AdvancedOrder calldata advancedOrder, CriteriaResolver[] calldata criteriaResolver, bytes32 fulfillerConduitKey, address recipient) external payable returns (bool fulfilled);
    function cancel(OrderComponents[] calldata orders) external returns (bool cancelled);
    function getCounter(address offerer) external view returns (uint256 counter);
}

interface ISeaportValidator {
    function validateOfferItems(OrderParameters memory orderParameters) external view returns (ErrorsAndWarnings memory errorsAndWarnings);
}

interface IERC721 {
    function getApproved(uint256 tokenId) external view returns (address operator);
}

