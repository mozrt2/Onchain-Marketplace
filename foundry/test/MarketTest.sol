// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/OnchainMarketplace.sol";

contract MarketTest is Test, OnchainMarketplace {

    constructor() OnchainMarketplace (0x00000000000001ad428e4906aE43D8F9852d0dD6,  0x0000000000000000000000000000000000000000000000000000000000000000) {}

    function test_Sell() public {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: 0xA29926934846fBF1000B5BCE7a309a89dFB6F05A,
            identifierOrCriteria: 2223,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: 0x0000000000000000000000000000000000000000,
            identifierOrCriteria: 0,
            startAmount: 600000000000000000,
            endAmount: 600000000000000000,
            recipient: payable(0xD8C5039F47220f21a2Cf86eF80b8146F73D01d32)
        });

        Order memory order =  Order({
                parameters: OrderParameters({
                    offerer: 0xD8C5039F47220f21a2Cf86eF80b8146F73D01d32,
                    zone: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,//address(this),
                    offer: offer,
                    consideration: consideration,
                    orderType: OrderType.FULL_OPEN,
                    startTime: 1679646470,
                    endTime: 1687422470,
                    zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    salt: 50000,
                    conduitKey: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    totalOriginalConsiderationItems: 1
                }),
                signature: hex"6873498e719f76e315c73f3f4a90ec558408082a469f3dfa11cd1abc8cdda4c32f2f26a24a9c75f3771483841c532930143fb4cc66508e1fc0f935e1a1802d731c"
        });  

        sell(order);
        this.buy{value: 600000000000000000}(0xA29926934846fBF1000B5BCE7a309a89dFB6F05A, 2223, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        bool isActive = getOrderStatus(0xA29926934846fBF1000B5BCE7a309a89dFB6F05A, 2223);
        console2.log("isActive: ", isActive);
    } 
}
// tests to run:
// add a new order via sell function
// check if the order is added to the orders mapping
// check if the order is added to the tokenIdsWithOrders mapping
// buy the order via buy function
// check if the order is deleted from the orders mapping
// check if the order is deleted from the tokenIdsWithOrders mapping