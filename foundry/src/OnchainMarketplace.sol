// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MarketMap.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/// @title Onchain Marketplace
/// @author mozrt (mozrt.eth)
/// @notice This contract is the onchain frontend for MarketMap, an onchain marketplace database connected to Seaport.

contract OnchainMarketplace is MarketMap {

    string public contractAddress;

    /// @dev Initializes the OnchainMarketplace contract.
    /// @param _seaportAddress The address of the seaport contract.
    /// @param _seaportValidatorAddress The address of the seaport validator contract.
    /// @param _conduitKey The conduit key for the seaport contract.
    constructor (
    address _seaportAddress, 
    address _seaportValidatorAddress, 
    bytes32 _conduitKey
    ) MarketMap (
        _seaportAddress, 
        _seaportValidatorAddress, 
        _conduitKey
    ) {
        contractAddress = toAsciiString(address(this));
    }

    /// @dev Converts an address to an ASCII string.
    /// @param x The address to be converted.
    /// @return The address as an ASCII string.
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i+2] = char(hi);
            s[2*i+1+2] = char(lo);            
        }
        return string(s);
    }

    /// @dev Converts a byte to a character.
    /// @param b The byte to be converted.
    /// @return c The byte as a character.
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /// @notice Returns the HTML for the Onchain Marketplace interface.
    /// @return The full HTML string.
    function html() public view returns (string memory) {
        string memory fullHTML = string(abi.encodePacked(htmlFirst, contractAddress, htmlSecond));
        return fullHTML;
    } 

    /// @notice Returns the Base64 encoded HTML for the Onchain Marketplace interface.
    /// @return The Base64 encoded HTML string.
    function htmlBase64() public view returns (string memory) {
        string memory prefix = "data:text/html;base64,";
        string memory fullHTML = html();
        string memory base64 = Base64.encode(bytes(fullHTML));
        return string(abi.encodePacked(prefix, base64));
    }

    string htmlFirst = "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><script>const contractAddress='" ;

    string htmlSecond = unicode"';function connect(){window.ethereum.request({method:'eth_requestAccounts'}).then(accounts=>{const account=accounts[0];document.getElementById('walletAddress').innerHTML=account,document.getElementById('welcome').innerHTML='Welcome '}).catch(error=>{document.getElementById('walletAddress').innerHTML=error}),window.ethereum.request({method:'wallet_switchEthereumChain',params:[{chainId:'0x5'}]}),window.ethereum.request({method:'net_version'}).then(result=>{5!=result&&(document.getElementById('network').innerHTML='Please connect to the Goerli test network before you continue.')});let token=document.getElementById('tokenAddress').value.slice(2);''==token&&(token='a29926934846fbf1000b5bce7a309a89dfb6f05a'),document.getElementById('forSale').innerHTML='Loading...';const container=document.getElementById('forSale');window.ethereum.request({method:'eth_call',params:[{to:contractAddress,data:'0x093376fe000000000000000000000000'+token},'latest']}).then(result=>{container.innerHTML='';const count=result.substring(66,130),countClean=parseInt(count,10),ids=[];for(let i=0;i<countClean;i++){const substring=result.substring(130+64*i,130+64*(i+1)),substringClean=Number(parseInt(substring,16));ids.push(substringClean);const data='0x793b8c6d000000000000000000000000'+token+substring;window.ethereum.request({method:'eth_call',params:[{to:contractAddress,data:data},'latest']}).then(result=>{const endTime=result.substring(194,258),endTimeClean=Number(parseInt(endTime,16)),endTimeDate=new Date(1e3*endTimeClean);if(result.substring(2,66)!='0'.repeat(64)&&endTimeClean>(new Date).getTime()/1e3){const newItem=document.createElement('div');newItem.id=substringClean,newItem.style='border: 1px solid black; padding: 1vh; margin-right: 1vh; margin-top:1vh;',container.appendChild(newItem);const overTitle=document.createElement('p');overTitle.innerHTML='token no.',newItem.appendChild(overTitle);const title=document.createElement('h3');title.innerHTML=substringClean,newItem.appendChild(title);const data=document.createElement('p');data.innerHTML='for sale until '+endTimeDate.toLocaleDateString(),newItem.appendChild(data);const buyButton=document.createElement('button'),price=result.substring(66,130),priceClean=(Number(parseInt(price,16))/1e18).toFixed(2);buyButton.innerHTML='Buy now Ξ'+priceClean;const account=document.getElementById('walletAddress').innerHTML.slice(2);buyButton.onclick=()=>{buy('0x'+price,token,substring,account)},newItem.appendChild(buyButton)}}).catch(error=>{console.error(error)})}const sell=document.getElementById('sell');sell.style='display: block;'}).catch(error=>{console.error(error)})}async function sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt){const seaportAddress='0x00000000000001ad428e4906aE43D8F9852d0dD6'.slice(2),tokenIdBigInt=BigInt(tokenId).toString(16),calldata_1='0x081812fc',calldata_2='0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,calldata=calldata_1+calldata_2,result=await window.ethereum.request({method:'eth_call',params:[{from:walletAddress,to:tokenAddress,data:calldata},'latest']});if(console.log(result.slice(-40)),result.slice(-40)!=seaportAddress.toLowerCase()){const calldata_1b='0x095ea7b3',calldata_2b='0'.repeat(64-seaportAddress.length)+seaportAddress,calldata_b=calldata_1b+calldata_2b+calldata_2;await window.ethereum.request({method:'eth_sendTransaction',params:[{from:walletAddress,to:tokenAddress,data:calldata_b}]})}const msgParams=JSON.stringify({types:{EIP712Domain:[{name:'name',type:'string'},{name:'version',type:'string'},{name:'chainId',type:'uint256'},{name:'verifyingContract',type:'address'}],OrderComponents:[{name:'offerer',type:'address'},{name:'zone',type:'address'},{name:'offer',type:'OfferItem[]'},{name:'consideration',type:'ConsiderationItem[]'},{name:'orderType',type:'uint8'},{name:'startTime',type:'uint256'},{name:'endTime',type:'uint256'},{name:'zoneHash',type:'bytes32'},{name:'salt',type:'uint256'},{name:'conduitKey',type:'bytes32'},{name:'counter',type:'uint256'}],OfferItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'}],ConsiderationItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'},{name:'recipient',type:'address'}]},primaryType:'OrderComponents',domain:{name:'Seaport',version:'1.4',chainId:'5',verifyingContract:'0x00000000000001ad428e4906aE43D8F9852d0dD6'},message:{offerer:walletAddress,offer:[{itemType:'2',token:tokenAddress,identifierOrCriteria:String(tokenId),startAmount:'1',endAmount:'1'}],consideration:[{itemType:'0',token:'0x0000000000000000000000000000000000000000',identifierOrCriteria:'0',startAmount:String(priceWei),endAmount:String(priceWei),recipient:walletAddress}],orderType:'0',startTime:String(startTime),endTime:String(endTime),zone:contractAddress,zoneHash:'0x0000000000000000000000000000000000000000000000000000000000000000',salt:String(salt),conduitKey:'0x0000000000000000000000000000000000000000000000000000000000000000',counter:'0'}}),signature=await window.ethereum.request({method:'eth_signTypedData_v4',params:[walletAddress,msgParams]});return signature}async function sell(){const walletAddress=document.getElementById('walletAddress').textContent,tokenAddress=document.getElementById('tokenAddress').value,tokenId=document.getElementById('tokenId').value,price=document.getElementById('price').value,duration=document.getElementById('duration').value,priceWei=1e18*price,durationSeconds=86400*duration,startTime=Math.floor(Date.now()/1e3),endTime=Math.floor(Date.now()/1e3)+durationSeconds,salt=Math.floor(1e5*Math.random()),signature=await sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt),startTimeBigInt=BigInt(startTime).toString(16),endTimeBigInt=BigInt(endTime).toString(16),saltBigInt=BigInt(salt).toString(16),priceWeiBigInt=BigInt(priceWei).toString(16),tokenIdBigInt=BigInt(tokenId).toString(16),zero='0'.repeat(64),one='0'.repeat(63)+'1',calldata_1='0x59ce0ec5',calldata_2='0'.repeat(62)+'20',calldata_3='0'.repeat(62)+'40',calldata_4='0'.repeat(61)+'340',calldata_5='0'.repeat(24)+walletAddress.slice(2).toLowerCase(),calldata_6=zero,calldata_7='0'.repeat(61)+'160',calldata_8='0'.repeat(61)+'220',calldata_9=zero,calldata_10='0'.repeat(64-startTimeBigInt.length)+startTimeBigInt,calldata_11='0'.repeat(64-endTimeBigInt.length)+endTimeBigInt,calldata_12=zero,calldata_13='0'.repeat(64-saltBigInt.length)+saltBigInt,calldata_14=zero,calldata_15=one,calldata_16=one,calldata_17='0'.repeat(63)+'2',calldata_18='0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),calldata_19='0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,calldata_20=one,calldata_21=one,calldata_22=one,calldata_23=zero,calldata_24=zero,calldata_25=zero,calldata_26='0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,calldata_27='0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,calldata_28='0'.repeat(24)+walletAddress.slice(2).toLowerCase(),calldata_29='0'.repeat(62)+'41'+signature.slice(2)+'0'.repeat(62),calldata=calldata_1+calldata_2+calldata_3+calldata_4+calldata_5+calldata_6+calldata_7+calldata_8+calldata_9+calldata_10+calldata_11+calldata_12+calldata_13+calldata_14+calldata_15+calldata_16+calldata_17+calldata_18+calldata_19+calldata_20+calldata_21+calldata_22+calldata_23+calldata_24+calldata_25+calldata_26+calldata_27+calldata_28+calldata_29;window.ethereum.request({method:'eth_sendTransaction',params:[{from:walletAddress,to:contractAddress,data:calldata}]})}function buy(amount,token,tokenId,recipient){const walletAddress=document.getElementById('walletAddress').textContent,calldata_1='0xdb61c76e',calldata_2='0'.repeat(64-token.length)+token,calldata_3=tokenId,calldata_4='0'.repeat(64-recipient.length)+recipient,calldata=calldata_1+calldata_2+calldata_3+calldata_4;window.ethereum.request({method:'eth_sendTransaction',params:[{from:walletAddress,to:contractAddress,value:amount,data:calldata}]})}function cancel(){const walletAddress=document.getElementById('walletAddress').textContent,tokenAddress=document.getElementById('tokenAddress').value,tokenId=document.getElementById('tokenIdCancel').value,tokenIdBigInt=BigInt(tokenId).toString(16),calldata_1='0x6a206137',calldata_2='0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),calldata_3='0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,calldata=calldata_1+calldata_2+calldata_3;window.ethereum.request({method:'eth_sendTransaction',params:[{from:walletAddress,to:contractAddress,data:calldata}]})}</script></head><body><div><h1>Onchain Marketplace v0.0.1</h1><p style='font-weight: bold;'>An onchain frontend and database for ERC721 trading on top of Seaport Protocol.</p><p>⚠️Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet⚠️</p></div><div><span id='welcome'>Welcome!</span><span id='walletAddress'></span><p>Start by typing the address of the collection you would like to buy or sell from in the box below (defaults to the Terraform Automata Goerli collection) and connect your wallet with the 'Load Collection' button (make sure to be on the Goerli network). All content is loaded via RPC requests sent to your wallet provider.</p><input type='text' id='tokenAddress' name='tokenAddress' value='0xa29926934846fbf1000b5bce7a309a89dfb6f05a' /><button onclick='connect()'>Load Collection</button></div><h2 id='network'></h2><div id='forSale' style='display: flex; flex-wrap: wrap;'></div><div style='display: none;' id='sell'><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Sell an item from this collection</h3><input type='number' id='tokenId' placeholder='token id'/><input type='number' id='price' placeholder='price (eth)'/><input type='number' id='duration' placeholder='duration (days)'/><button onclick='sell()' class='sell'>Sell</button><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Cancel a sale from this collection</h3><input type='number' id='tokenIdCancel' placeholder='token id'/><button onclick='cancel()' class='sell'>Cancel</button><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Further information</h3><p style='font-weight: bold;'>Buy and cancel orders can be approved directly with one simple wallet transaction. Sell orders however require a few more steps:</p><ul><li><span style='font-weight: bold;'>Give Seaport access to your NFT:</span>If you haven't approved this NFT for sale previously, you will be asked to give the Seaport contract access to it (0x00000000000001ad428e4906aE43D8F9852d0dD6). This is the same procedure as approving a collection for the first time on Opensea, with the added safety of only approving one specific NFT from the collection.</li><li><span style='font-weight: bold;'>Sign your sell order:</span>Next, you will be asked to sign your sell order. Your wallet will show you the parameters of the order before signing. This is required for each sale, and functions the same on Opensea.</li><li><span style='font-weight: bold;'>Save the order in the Onchain Marketplace database:</span>One final step is required to store your sell order in the Onchain Marketplace storage, this is the last transaction that will appear on your screen. Marketplaces such as Opensea don't require this step as they store your order off-chain.</li></ul></div></body></html>";
    
}