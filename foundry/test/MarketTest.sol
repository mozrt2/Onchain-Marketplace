// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/OnchainMarketplace.sol";

contract MarketTest is Test, OnchainMarketplace {

    constructor() OnchainMarketplace (0x00000000000001ad428e4906aE43D8F9852d0dD6,  0x0000a26b00c1F0DF003000390027140000fAa719,25000000000000000,0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,"0xa29926934846fbf1000b5bce7a309a89dfb6f05a") {}

    function test_Sell() public {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: 0xA29926934846fBF1000B5BCE7a309a89dFB6F05A,
            identifierOrCriteria: 2223,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: 0x0000000000000000000000000000000000000000,
            identifierOrCriteria: 0,
            startAmount: 18000000000000000000000,
            endAmount: 18000000000000000000000,
            recipient: payable(0xD8C5039F47220f21a2Cf86eF80b8146F73D01d32)
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: 0x0000000000000000000000000000000000000000,
            identifierOrCriteria: 0,
            startAmount: 10000000000,
            endAmount: 10000000000,
            recipient: payable(0x9B3840c4AF9cBd0181b3A1E4A706335fA23Cc5E7)
        });

        Order memory order =  Order({
                parameters: OrderParameters({
                    offerer: 0xD8C5039F47220f21a2Cf86eF80b8146F73D01d32,
                    zone: 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,//address(this),
                    offer: offer,
                    consideration: consideration,
                    orderType: OrderType.FULL_OPEN,
                    startTime: 1680465331,
                    endTime: 1688241331,
                    zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    salt: 50000,
                    conduitKey: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    totalOriginalConsiderationItems: 2
                }),
                signature: hex"c6e30380153f05ab2214a4d1815da870f6cf4a3ce7dd09e284510d3dff40d9ec741c111b414946712226d2ba0d8f2514dcd8867b4becc40931ead169c1ffe7e31c"
        });  

        console2.log(html());
        sell(order,"");
        console2.log("order: ", orders[0xA29926934846fBF1000B5BCE7a309a89dFB6F05A][2223].amount, "royalty:", additionalRecipients[0xA29926934846fBF1000B5BCE7a309a89dFB6F05A][2223][1].amount);
        //hex"88f232d7a197aeab312ec4181215e5e8c90f6769af8b6b685e5a369a7495fe4b20dfbdd46f132a7bc2c813cb4f8c128491a3238e6225e074b1efe496c66a1b3b1c");
        this.buy{value: 18000000000010000000000}(0xA29926934846fBF1000B5BCE7a309a89dFB6F05A, 2223, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
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