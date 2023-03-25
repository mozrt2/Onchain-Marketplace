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
    /// @param _conduitKey The conduit key for the seaport contract.
    constructor (
    address _seaportAddress, 
    bytes32 _conduitKey
    ) MarketMap (
        _seaportAddress, 
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

    string htmlSecond = unicode"',request=(method,params)=>window.ethereum.request({method:method,params:params}),getHtml=id=>document.getElementById(id),setHtml=(id,html)=>document.getElementById(id).innerHTML=html,createHtml=tag=>document.createElement(tag),toHex=num=>BigInt(num).toString(16);function connect(){request('eth_requestAccounts').then(accounts=>{setHtml('walletAddress',accounts[0]),setHtml('welcome','Welcome ')}).catch(error=>{setHtml('walletAddress',error)}),request('wallet_switchEthereumChain',[{chainId:'0x5'}]),request('net_version').then(result=>{5!=result&&setHtml('network','Please connect to the Goerli test network before you continue.')});const token=getHtml('tokenAddress').value.slice(2)||'a29926934846fbf1000b5bce7a309a89dfb6f05a';setHtml('forSale','Loading...');const container=getHtml('forSale');request('eth_call',[{to:contractAddress,data:'0x093376fe000000000000000000000000'+token},'latest']).then(result=>{container.innerHTML='';const countClean=parseInt(result.substring(66,130),10),ids=[];for(let i=0;i<countClean;i++){const id=result.substring(130+64*i,130+64*(i+1)),idClean=Number(parseInt(id,16));ids.push(idClean);const data='0x793b8c6d000000000000000000000000'+token+id;request('eth_call',[{to:contractAddress,data:data},'latest']).then(result=>{const endTime=Number(parseInt(result.substring(130,194),16)),endTimeDate=new Date(1e3*endTime);if(result.substring(2,66)!='0'.repeat(64)&&endTime>(new Date).getTime()/1e3){const newItem=createHtml('div');newItem.id=idClean,newItem.style='border: 1px solid black; padding: 1vh; margin-right: 1vh; margin-top:1vh;',container.appendChild(newItem),newItem.innerHTML=`<p>token no.</p><h3>${idClean}</h3><p>for sale until ${endTimeDate.toLocaleDateString()}</p>`;const buyButton=createHtml('button'),price=result.substring(2,66),priceClean=(Number(parseInt(price,16))/1e5).toFixed(2),priceWei=toHex(1e18*priceClean),priceWei32='0'.repeat(64-priceWei.length)+priceWei;buyButton.innerHTML='Buy now Ξ'+priceClean;const account=getHtml('walletAddress').innerHTML.slice(2);buyButton.onclick=()=>{buy('0x'+priceWei32,token,id,account)},newItem.appendChild(buyButton)}})}getHtml('sell').style='display: block;'})}async function sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt){const seaportAddress='0x00000000000001ad428e4906aE43D8F9852d0dD6'.slice(2),tokenIdBigInt=BigInt(tokenId).toString(16),idCalldata='0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,calldata='0x081812fc'+idCalldata,result=await request('eth_call',[{from:walletAddress,to:tokenAddress,data:calldata},'latest']);if(result.slice(-40)!=seaportAddress.toLowerCase()){const calldata2='0x095ea7b3'+'0'.repeat(64-seaportAddress.length)+seaportAddress+idCalldata;await request('eth_sendTransaction',[{from:walletAddress,to:tokenAddress,data:calldata2}])}const msgParams=JSON.stringify({types:{EIP712Domain:[{name:'name',type:'string'},{name:'version',type:'string'},{name:'chainId',type:'uint256'},{name:'verifyingContract',type:'address'}],OrderComponents:[{name:'offerer',type:'address'},{name:'zone',type:'address'},{name:'offer',type:'OfferItem[]'},{name:'consideration',type:'ConsiderationItem[]'},{name:'orderType',type:'uint8'},{name:'startTime',type:'uint256'},{name:'endTime',type:'uint256'},{name:'zoneHash',type:'bytes32'},{name:'salt',type:'uint256'},{name:'conduitKey',type:'bytes32'},{name:'counter',type:'uint256'}],OfferItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'}],ConsiderationItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'},{name:'recipient',type:'address'}]},primaryType:'OrderComponents',domain:{name:'Seaport',version:'1.4',chainId:'5',verifyingContract:'0x00000000000001ad428e4906aE43D8F9852d0dD6'},message:{offerer:walletAddress,offer:[{itemType:'2',token:tokenAddress,identifierOrCriteria:String(tokenId),startAmount:'1',endAmount:'1'}],consideration:[{itemType:'0',token:'0x0000000000000000000000000000000000000000',identifierOrCriteria:'0',startAmount:String(priceWei),endAmount:String(priceWei),recipient:walletAddress}],orderType:'0',startTime:String(startTime),endTime:String(endTime),zone:contractAddress,zoneHash:'0x0000000000000000000000000000000000000000000000000000000000000000',salt:String(salt),conduitKey:'0x0000000000000000000000000000000000000000000000000000000000000000',counter:'0'}}),signature=await request('eth_signTypedData_v4',[walletAddress,msgParams]);return signature}async function sell(){const walletAddress=getHtml('walletAddress').textContent,tokenAddress=getHtml('tokenAddress').value,tokenId=getHtml('tokenId').value,price=getHtml('price').value,duration=getHtml('duration').value,priceWei=1e18*price,durationSeconds=86400*duration,startTime=Math.floor(Date.now()/1e3),endTime=Math.floor(Date.now()/1e3)+durationSeconds,salt=Math.floor(64999*Math.random()),startTimeBigInt=toHex(startTime),endTimeBigInt=toHex(endTime),saltBigInt=toHex(salt),priceWeiBigInt=toHex(priceWei),tokenIdBigInt=toHex(tokenId),signature=await sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt),zero='0'.repeat(64),one='0'.repeat(63)+'1',calldataSegments=['0x59ce0ec5','0'.repeat(62)+'20','0'.repeat(62)+'40','0'.repeat(61)+'340','0'.repeat(24)+walletAddress.slice(2).toLowerCase(),'0'.repeat(24)+contractAddress.slice(2).toLowerCase(),'0'.repeat(61)+'160','0'.repeat(61)+'220',zero,'0'.repeat(64-startTimeBigInt.length)+startTimeBigInt,'0'.repeat(64-endTimeBigInt.length)+endTimeBigInt,zero,'0'.repeat(64-saltBigInt.length)+saltBigInt,zero,one,one,'0'.repeat(63)+'2','0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),'0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,one,one,one,zero,zero,zero,'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(24)+walletAddress.slice(2).toLowerCase(),'0'.repeat(62)+'41'+signature.slice(2)+'0'.repeat(62)],calldata=calldataSegments.join('');request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,data:calldata}])}function buy(amount,token,tokenId,recipient){const walletAddress=getHtml('walletAddress').textContent,calldataSegments=['0xdb61c76e','0'.repeat(64-token.length)+token,tokenId,'0'.repeat(64-recipient.length)+recipient],calldata=calldataSegments.join('');request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,value:amount,data:calldata}])}function cancel(){const walletAddress=getHtml('walletAddress').textContent,tokenAddress=getHtml('tokenAddress').value,tokenIdBigInt=toHex(getHtml('tokenIdCancel').value),calldataSegments=['0x6a206137','0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),'0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt],calldata=calldataSegments.join('');request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,data:calldata}])}</script></head><body><div><h1>Onchain Marketplace v0.0.2</h1><p style='font-weight: bold;'>An onchain frontend and database for ERC721 trading on top of Seaport Protocol.</p><p>⚠️Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet⚠️</p></div><div><span id='welcome'>Welcome!</span><span id='walletAddress'></span><p>Start by typing the address of the collection you would like to buy or sell from in the box below (defaults to the Terraform Automata Goerli collection) and connect your wallet with the 'Load Collection' button (make sure to be on the Goerli network). All content is loaded via RPC requests sent to your wallet provider.</p><input type='text' id='tokenAddress' name='tokenAddress' value='0xa29926934846fbf1000b5bce7a309a89dfb6f05a' /><button onclick='connect()'>Load Collection</button></div><h2 id='network'></h2><div id='forSale' style='display: flex; flex-wrap: wrap;'></div><div style='display: none;' id='sell'><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Sell an item from this collection</h3><input type='number' id='tokenId' placeholder='token id'/><input type='number' id='price' placeholder='price (eth)'/><input type='number' id='duration' placeholder='duration (days)'/><button onclick='sell()' class='sell'>Sell</button><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Cancel a sale from this collection</h3><input type='number' id='tokenIdCancel' placeholder='token id'/><button onclick='cancel()' class='sell'>Cancel</button><h3 style='margin-top: 5vh; margin-bottom: 0.5vh;'>Further information</h3><p style='font-weight: bold;'>Buy and cancel orders can be approved directly with one simple wallet transaction. Sell orders however require a few more steps:</p><ul><li><span style='font-weight: bold;'>Give Seaport access to your NFT: </span>If you haven't approved this NFT for sale previously, you will be asked to give the Seaport contract access to it (0x00000000000001ad428e4906aE43D8F9852d0dD6). This is the same procedure as approving a collection for the first time on Opensea, with the added safety of only approving one specific NFT from the collection.</li><li><span style='font-weight: bold;'>Sign your sell order: </span>Next, you will be asked to sign your sell order. Your wallet will show you the parameters of the order before signing. This is required for each sale, and functions the same on Opensea.</li><li><span style='font-weight: bold;'>Save the order in the Onchain Marketplace database: </span>One final step is required to store your sell order in the Onchain Marketplace storage, this is the last transaction that will appear on your screen. Marketplaces such as Opensea don't require this step as they store your order off-chain.</li></ul></div></body></html>";
    
}