// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/Storefront.sol";

contract MarketTest is Test, Storefront {

    constructor() Storefront (0x00000000000001ad428e4906aE43D8F9852d0dD6, 0xF75194740067D6E4000000003b350688DD770000,  0x0000000000000000000000000000000000000000000000000000000000000000) {}

/*    function test_Sell() public {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: 0xA29926934846fBF1000B5BCE7a309a89dFB6F05A,
            identifierOrCriteria: 3425,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: 0x0000000000000000000000000000000000000000,
            identifierOrCriteria: 0,
            startAmount: 10000000000000000,
            endAmount: 10000000000000000,
            recipient: payable(0x9Cb5433d5C5BDdc5C480103F06f03dB13b36b7C9)
        });

        Order memory order =  Order({
                parameters: OrderParameters({
                    offerer: 0x9Cb5433d5C5BDdc5C480103F06f03dB13b36b7C9,
                    zone: address(this),
                    offer: offer,
                    consideration: consideration,
                    orderType: OrderType.FULL_OPEN,
                    startTime: 1678817397,
                    endTime: 1681495797,
                    zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    salt: 24446,
                    conduitKey: 0x0000000000000000000000000000000000000000000000000000000000000000,
                    totalOriginalConsiderationItems: 1
                }),
                signature: hex"eeae21145d530467add066f59125cff87caa55375c2972e88d0af889d537c08d4a5f2878acc92dffd6b3af16c2ca20afe1dbba525d904964e56909903c184cb41c"
        });  

        sell(order);

    } 

    function test_HTML () public view {
        string memory html = html(); 
        console2.log(html);
    } */ 
}
// tests to run:
// add a new order via sell function

// 304, 1100 [["0x9Cb5433d5C5BDdc5C480103F06f03dB13b36b7C9", "0x0000000000000000000000000000000000000000",[[2, "0xA29926934846fBF1000B5BCE7a309a89dFB6F05A", 3425, 1, 1]], [[0, "0x0000000000000000000000000000000000000000", 0, "10000000000000000", "10000000000000000", "0x9Cb5433d5C5BDdc5C480103F06f03dB13b36b7C9"]], 0, 1678817397, 1681495797, "0x0000000000000000000000000000000000000000000000000000000000000000", "24446860302761739304752683030156737591518664810215442929818309915056373538701", "0x0000000000000000000000000000000000000000000000000000000000000000", 1], "0xeeae21145d530467add066f59125cff87caa55375c2972e88d0af889d537c08d4a5f2878acc92dffd6b3af16c2ca20afe1dbba525d904964e56909903c184cb41c"]

// check if the order is added to the orders mapping
// check if the order is added to the tokenIdsWithOrders mapping
// buy the order via buy function
// check if the order is deleted from the orders mapping
// check if the order is deleted from the tokenIdsWithOrders mapping