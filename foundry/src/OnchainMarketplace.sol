// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./MarketMap.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/// @title Onchain Marketplace
/// @author mozrt (mozrt.eth)
/// @notice This contract is the onchain frontend for MarketMap, an onchain marketplace database connected to Seaport.

contract OnchainMarketplace is MarketMap {

    string public contractAddress;
    string public defaultCollection;

    /// @dev Initializes the OnchainMarketplace contract.
    /// @param _seaportAddress The address of the Seaport contract.
    /// @param _openseaAddress The address of the OpenSea contract.
    /// @param _openseaFee The fee charged by Opensea for a sale of 1 ETH.
    /// @param _openseaConduitKey The key for the Opensea Conduit.
    /// @param _defaultCollection The default NFT collection for the frontend.
    constructor (
    address _seaportAddress,
    address _openseaAddress,
    uint256 _openseaFee,
    bytes32 _openseaConduitKey,
    string memory _defaultCollection
    ) MarketMap (
        _seaportAddress, 
        _openseaAddress,
        _openseaFee,
        _openseaConduitKey
    ) {
        contractAddress = addressToString(address(this));
        defaultCollection = _defaultCollection;
    }

    /// @notice Returns the HTML for the Onchain Marketplace interface.
    /// @return The full HTML string.
    function html() view public returns (string memory) {
        string memory fullHTML = string(abi.encodePacked(htmlBegin(), htmlEnd()));
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

    /// @dev Returns the initial part of the HTML for the Onchain Marketplace interface.
    /// @return The initial HTML string.
    function htmlBegin() view internal returns (string memory) {
        string memory htmlInitial = string(abi.encodePacked(htmlFirst, contractAddress, htmlSecond, addressToString(seaportAddress), htmlThird, addressToString(openseaAddress)));
        return htmlInitial;        
    }

    /// @dev Returns the final part of the HTML for the Onchain Marketplace interface.
    /// @return The final HTML string.
    function htmlEnd() view internal returns (string memory) {
        string memory htmlFinal = string(abi.encodePacked(htmlFourth, uintToString(openseaFee), htmlFifth, bytes32ToString(openseaConduitKey), htmlSixth, defaultCollection, htmlSeventh));
        return htmlFinal;
    }

    /// @dev Converts an Ethereum address to a string representation.
    /// @param x The Ethereum address to be converted.
    /// @return The Ethereum address as a string.
    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            s[2*i] = byteToChar(uint8(b) / 16);
            s[2*i+1] = byteToChar(uint8(b) % 16);
        }
        return string(abi.encodePacked("0x", s));
    }

    /// @dev Converts an unsigned integer to a string representation.
    /// @param x The unsigned integer to be converted.
    /// @return The unsigned integer as a string.
    function uintToString(uint x) internal pure returns (string memory) {
        if (x == 0) {
            return "0";
        }
        bytes memory buffer = new bytes(100);
        uint i = 0;
        while (x > 0) {
            buffer[i++] = byteToChar(uint8(x % 10));
            x /= 10;
        }
        bytes memory result = new bytes(i);
        for (uint j = 0; j < i; j++) {
            result[j] = buffer[i - 1 - j];
        }
        return string(result);
    }

    /// @dev Converts a bytes32 value to a string representation.
    /// @param x The bytes32 value to be converted.
    /// @return The bytes32 value as a string.
    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            s[2*i] = byteToChar(uint8(x[i]) / 16);
            s[2*i+1] = byteToChar(uint8(x[i]) % 16);
        }
        return string(abi.encodePacked("0x", s));
    }

    /// @dev Converts a single uint8 value to its corresponding ASCII character.
    /// @param b The uint8 value to be converted.
    /// @return c The corresponding ASCII character as a bytes1 value.    
    function byteToChar(uint8 b) private pure returns (bytes1 c) {
        return (b < 10) ? bytes1(b + 0x30) : bytes1(b + 0x57);
    }

    string htmlFirst = "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><script>const contractAddress='" ;
    string htmlSecond = "',seaport='";
    string htmlThird = "',openseaAddress='";
    string htmlFourth = "',openseaFee=";
    string htmlFifth = "/1e18,openseaConduitKey='";
    string htmlSixth = "',defaultCollection='";
    string htmlSeventh = unicode"';let royalties,royaltyAddress,incRoyalties,incOpensea;const request=(method,params)=>window.ethereum.request({method:method,params:params}),getHtml=id=>document.getElementById(id),setHtml=(id,html)=>document.getElementById(id).innerHTML=html,createHtml=(tag,options)=>{const element=document.createElement(tag);for(const key in options)element[key]=options[key];return element},toHex=num=>BigInt(num).toString(16);async function connect(){try{const accounts=await request('eth_requestAccounts');setHtml('walletAddress',accounts[0]),setHtml('welcome','Welcome ')}catch(error){setHtml('txStatus',error)}request('wallet_switchEthereumChain',[{chainId:'0x5'}]);const networkVersion=await request('net_version');if(5!=networkVersion)return void setHtml('txStatus','Please connect to the Goerli test network before you continue.');const token=getHtml('tokenAddress').value.slice(2)||defaultCollection.toLowerCase().slice(2);setHtml('txStatus','Loading...'),setHtml('forSale','');const container=getHtml('forSale');checkRoyalties(token);const tokenList=await request('eth_call',[{to:contractAddress,data:'0x093376fe000000000000000000000000'+token},'latest']),countClean=parseInt(tokenList.substring(66,130),10),ids=[];for(let i=0;i<countClean;i++){const id=tokenList.substring(130+64*i,130+64*(i+1)),idClean=Number(parseInt(id,16));ids.push(idClean);const token32='0'.repeat(64-token.length)+token,idHex=toHex(idClean),id32='0'.repeat(64-idHex.length)+idHex,data='0xa80a3baa'+token32+id32,isActive=await request('eth_call',[{to:contractAddress,data:data},'latest']);if(isActive.substring(2,66)!='0'.repeat(64)){const data='0x793b8c6d000000000000000000000000'+token+id,orderData=await request('eth_call',[{to:contractAddress,data:data},'latest']),endTime=Number(parseInt(orderData.substring(130,194),16)),endTimeDate=new Date(1e3*endTime),price=orderData.substring(2,66),dataURI='0xc87b56dd'+id32,rawURI=await request('eth_call',[{to:'0x'+token,data:dataURI},'latest']),URI=await decodeTokenURI(rawURI),image=URI.image,name=URI.name||idClean,newItem=createHtml('div',{id:idClean,className:'tiles',style:'position: relative;'});container.appendChild(newItem),image&&newItem.appendChild(createHtml('img',{src:image,style:'max-height: 30vh; max-width: 45vw;',onclick:()=>detailPopUp(id32,token,'media'),className:'click'}));const itemTitle=createHtml('p',{style:'font-weight: bold; font-size: 0.85em; margin-bottom: -0.5vh; margin-top: 0.5vh; text-align: center; white-space: nowrap;'});itemTitle.appendChild(createHtml('span',{innerHTML:name,onclick:()=>detailPopUp(id32,token,'media'),className:'click'})),itemTitle.appendChild(createHtml('span',{innerHTML:' 🛈',style:'font-weight: lighter;',onclick:()=>detailPopUp(id32,token,'attributes'),className:'click'})),newItem.append(itemTitle,createHtml('p',{innerHTML:`for sale until ${endTimeDate.toLocaleDateString()}`,style:'font-weight: lighter; font-size: 0.7em; margin: 0px; margin-bottom: 0.5vh; text-align: center;',onclick:()=>detailPopUp(id32,token,'media'),className:'click'}));const buyButton=createHtml('button',{style:'padding: 0.6em 0.8em; font-size: 0.7em'}),priceClean=Number(parseInt(price,16))*(100+royalties)/100,priceWei=toHex(1e3*priceClean),priceWei32='0'.repeat(64-priceWei.length)+priceWei;buyButton.innerHTML='Buy now Ξ'+(priceClean/1e15).toFixed(3);const account=getHtml('walletAddress').innerHTML.slice(2);buyButton.onclick=()=>{buy('0x'+priceWei32,token,id,account)},newItem.appendChild(buyButton)}}getHtml('sell').style='display: block;',setHtml('txStatus','')}async function sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt,opensea){const seaportAddress=seaport.slice(2),tokenIdBigInt=BigInt(tokenId).toString(16),idCalldata='0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,calldata='0x081812fc'+idCalldata,result=await request('eth_call',[{from:walletAddress,to:tokenAddress,data:calldata},'latest']);if(result.slice(-40)!=seaportAddress.toLowerCase()){const calldata2='0x095ea7b3'+'0'.repeat(64-seaportAddress.length)+seaportAddress+idCalldata,tx=await request('eth_sendTransaction',[{from:walletAddress,to:tokenAddress,data:calldata2}]),receipt=await getTxReceipt(tx);setHtml('txStatus',`Transaction ${tx} ${receipt.status?'was successful.':'failed.'}`)}const counter=await getCounter(walletAddress);let openseaConsideration,royaltiesConsideration,os=!1;const royaltyPrice=priceWei*(royalties/100),openseaPrice=.025*(priceWei+royaltyPrice);royalties>0&&(royaltiesConsideration={itemType:'0',token:'0x0000000000000000000000000000000000000000',identifierOrCriteria:'0',startAmount:String(royaltyPrice),endAmount:String(royaltyPrice),recipient:royaltyAddress});let considerations=royaltiesConsideration?[royaltiesConsideration]:[],msgParams=createMsgParams(priceWei,walletAddress,tokenAddress,tokenId,startTime,endTime,salt,counter,considerations,os);const signature=await request('eth_signTypedData_v4',[walletAddress,msgParams]);let signatureOpensea='0x';return opensea&&(openseaConsideration={itemType:'0',token:'0x0000000000000000000000000000000000000000',identifierOrCriteria:'0',startAmount:String(openseaPrice),endAmount:String(openseaPrice),recipient:openseaAddress},considerations=[...openseaConsideration?[openseaConsideration]:[],...royaltiesConsideration?[royaltiesConsideration]:[]],os=!0,msgParams=createMsgParams(priceWei,walletAddress,tokenAddress,tokenId,startTime,endTime,salt,counter,considerations,os),signatureOpensea=await request('eth_signTypedData_v4',[walletAddress,msgParams])),[signature,signatureOpensea]}async function sell(){setHtml('txStatus','');const walletAddress=getHtml('walletAddress').textContent,tokenAddress=getHtml('tokenAddress').value,tokenId=getHtml('tokenId').value,price=getHtml('price').value,duration=getHtml('duration').value,opensea=getHtml('listOS').checked,priceWei=1e18*price,durationSeconds=86400*duration,startTime=Math.floor(Date.now()/1e3),endTime=Math.floor(Date.now()/1e3)+durationSeconds,salt=Math.floor(64999*Math.random()),startTimeBigInt=toHex(startTime),endTimeBigInt=toHex(endTime),saltBigInt=toHex(salt),priceWeiBigInt=toHex(priceWei),tokenIdBigInt=toHex(tokenId),royaltyPriceWeiBigInt=toHex(priceWei*(royalties/100)),zero='0'.repeat(64),one='0'.repeat(63)+'1';let bytesTwo,bytesFour,totalConsiderations,considerationBytes;if(royalties>0){bytesTwo='0'.repeat(61)+'4c0',bytesFour='0'.repeat(61)+'400',totalConsiderations='0'.repeat(63)+'2';const considerationBytesList=['0'.repeat(192),'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(24)+walletAddress.slice(2).toLowerCase(),'0'.repeat(192),'0'.repeat(64-royaltyPriceWeiBigInt.length)+royaltyPriceWeiBigInt,'0'.repeat(64-royaltyPriceWeiBigInt.length)+royaltyPriceWeiBigInt,'0'.repeat(24)+royaltyAddress.slice(2).toLowerCase()];considerationBytes=considerationBytesList.join('')}else{bytesTwo='0'.repeat(61)+'400',bytesFour='0'.repeat(61)+'340',totalConsiderations='0'.repeat(63)+'1';const considerationBytesList=['0'.repeat(192),'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(64-priceWeiBigInt.length)+priceWeiBigInt,'0'.repeat(24)+walletAddress.slice(2).toLowerCase()];considerationBytes=considerationBytesList.join('')}let[signature,signatureOpensea]=await sign(walletAddress,tokenAddress,tokenId,priceWei,startTime,endTime,salt,opensea);signatureOpensea='0x'==signatureOpensea?zero:'0'.repeat(62)+'41'+signatureOpensea.slice(2)+'0'.repeat(62);const calldataSegments=['0xe40abfcb','0'.repeat(62)+'40',bytesTwo,'0'.repeat(62)+'40',bytesFour,'0'.repeat(24)+walletAddress.slice(2).toLowerCase(),'0'.repeat(24)+contractAddress.slice(2).toLowerCase(),'0'.repeat(61)+'160','0'.repeat(61)+'220',zero,'0'.repeat(64-startTimeBigInt.length)+startTimeBigInt,'0'.repeat(64-endTimeBigInt.length)+endTimeBigInt,zero,'0'.repeat(64-saltBigInt.length)+saltBigInt,zero,totalConsiderations,one,'0'.repeat(63)+'2','0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),'0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt,one,one,totalConsiderations,considerationBytes,'0'.repeat(62)+'41'+signature.slice(2)+'0'.repeat(62),signatureOpensea],calldata=calldataSegments.join(''),tx=await request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,data:calldata}]),receipt=await getTxReceipt(tx);setHtml('txStatus',`Transaction ${tx} ${receipt.status?'was successful.':'failed.'}`)}async function buy(amount,token,tokenId,recipient){setHtml('txStatus','');const walletAddress=getHtml('walletAddress').textContent,calldataSegments=['0xdb61c76e','0'.repeat(64-token.length)+token,tokenId,'0'.repeat(64-recipient.length)+recipient],calldata=calldataSegments.join(''),tx=await request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,value:amount,data:calldata}]),receipt=await getTxReceipt(tx);setHtml('txStatus',`Transaction ${tx} ${receipt.status?'was successful.':'failed.'}`)}async function cancel(){setHtml('txStatus','');const walletAddress=getHtml('walletAddress').textContent,tokenAddress=getHtml('tokenAddress').value,tokenIdBigInt=toHex(getHtml('tokenIdCancel').value),calldataSegments=['0x6a206137','0'.repeat(24)+tokenAddress.slice(2).toLowerCase(),'0'.repeat(64-tokenIdBigInt.length)+tokenIdBigInt],calldata=calldataSegments.join(''),tx=await request('eth_sendTransaction',[{from:walletAddress,to:contractAddress,data:calldata}]),receipt=await getTxReceipt(tx);setHtml('txStatus',`Transaction ${tx} ${receipt.status?'was successful.':'failed.'}`)}async function getCounter(offerer){const calldata='0xf07ec373'+'0'.repeat(24)+offerer.slice(2).toLowerCase(),counter=await request('eth_call',[{to:seaport,data:calldata},'latest']);return counter}async function getTxReceipt(tx){let txReturn=await request('eth_getTransactionReceipt',[tx]);for(;null==txReturn;)txReturn=await request('eth_getTransactionReceipt',[tx]),setHtml('txStatus',`Transaction ${tx} is being processed...`);return txReturn}async function decodeTokenURI(result){const content=result.substring(130);let contentClean='';for(let i=0;i<content.length;i+=2){let hex=content.substr(i,2),char;contentClean+=String.fromCharCode(parseInt(hex,16))}if('data:application/json;base64,'==contentClean.slice(0,29))contentClean=reformatBase64(contentClean.slice(29)),contentClean=atob(contentClean),contentClean=JSON.parse(contentClean);else if('www'==contentClean.slice(0,3)||'htt'==contentClean.slice(0,3)){const response=await fetch(contentClean);contentClean=await response.json()}else if('ipf'==contentClean.slice(0,3)){const response=await fetch('https://ipfs.io/ipfs/'+contentClean);contentClean=await response.json()}const name=contentClean.name,description=contentClean.description,image=contentClean.image,animation_url=contentClean.animation_url,attributes=contentClean.attributes;return{name:name,description:description,image:image,animation_url:animation_url,attributes:attributes}}async function detailPopUp(id,token,mode){const dataURI='0xc87b56dd'+id,result=await request('eth_call',[{to:'0x'+token,data:dataURI},'latest']),decodedResult=await decodeTokenURI(result),popup=createHtml('div',{id:'detailPopUp',style:'position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.95); z-index: 1000; display: flex; flex-direction: column; justify-content: center; align-items: flex-start;'}),body=document.getElementsByTagName('body')[0];body.appendChild(popup);const close=createHtml('button',{onclick:()=>popup.remove(),style:'position: absolute; top: 0; right: 0; background: none; border: none; color: aliceblue; font-size: 2em;'});if(close.innerHTML='&times;',popup.appendChild(close),'media'==mode){let animation_url=decodedResult.animation_url,type='iframe';null==animation_url&&(animation_url=decodedResult.image,type='img');const animation=createHtml(type,{src:animation_url,style:'max-width: 90vw; min-height: 80vh; max-height: 95vh; object-fit: contain; object-position: center; border: 0; display: flex; flex-direction: column; padding-left: 10%;',scrolling:'no'});popup.appendChild(animation)}else if('attributes'==mode){let attributes=decodedResult.attributes;if(null==attributes)attributes=[],popup.appendChild(createHtml('span',{style:'padding-left: 30%;'})).innerHTML='No attributes available';else for(let i=0;i<attributes.length;i++){const attribute=createHtml('div',{style:'margin: 1vh; padding-left: 10%;'}),name=createHtml('span',{style:'font-weight: lighter;'});name.innerHTML=attributes[i].trait_type+': ';const value=createHtml('span',{style:'font-weight: bold;'});value.innerHTML=attributes[i].value,attribute.appendChild(name),attribute.appendChild(value),popup.appendChild(attribute)}}}function reformatBase64(input){const cleaned=input.replace(/[^A-Za-z0-9+/]/g,''),padding=cleaned.length%4==0?0:4-cleaned.length%4;return cleaned+'='.repeat(padding)}async function checkRoyalties(token){const calldata='0x2a55205a'+'0'.repeat(123)+'186a0';try{const result=await request('eth_call',[{to:'0x'+token,data:calldata},'latest']);royalties=Number(parseInt(result.slice(66),16))/1e3,royaltyAddress='0x'+result.slice(26,66),setHtml('royalties',royalties+'%')}catch(e){royalties=0,setHtml('royalties',royalties+'%')}}function updateTotal(){const price=getHtml('price').value,opensea=getHtml('listOS').checked;incRoyalties=price*(1+royalties/100),incOpensea=1.025*incRoyalties,setHtml('totalPrice',opensea?'Ξ'+incRoyalties.toFixed(5)+' here & Ξ'+incOpensea.toFixed(5)+' on OS':'Ξ'+incRoyalties.toFixed(5))}function moveDecimalLeft15(number){const strNum=number.toString(),decimalIndex=strNum.indexOf('.'),padSize=decimalIndex<0?15:15-decimalIndex,paddedStr=strNum.replace('.','').padStart(padSize+1,'0');return parseFloat(paddedStr.slice(0,-15)+'.'+paddedStr.slice(-15))}function createMsgParams(priceWei,walletAddress,tokenAddress,tokenId,startTime,endTime,salt,counter,considerations,os){let zone,conduitKey;return os?(zone='0x'+'0'.repeat(40),conduitKey=openseaConduitKey):(zone=contractAddress,conduitKey='0x'+'0'.repeat(64)),JSON.stringify({types:{EIP712Domain:[{name:'name',type:'string'},{name:'version',type:'string'},{name:'chainId',type:'uint256'},{name:'verifyingContract',type:'address'}],OrderComponents:[{name:'offerer',type:'address'},{name:'zone',type:'address'},{name:'offer',type:'OfferItem[]'},{name:'consideration',type:'ConsiderationItem[]'},{name:'orderType',type:'uint8'},{name:'startTime',type:'uint256'},{name:'endTime',type:'uint256'},{name:'zoneHash',type:'bytes32'},{name:'salt',type:'uint256'},{name:'conduitKey',type:'bytes32'},{name:'counter',type:'uint256'}],OfferItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'}],ConsiderationItem:[{name:'itemType',type:'uint8'},{name:'token',type:'address'},{name:'identifierOrCriteria',type:'uint256'},{name:'startAmount',type:'uint256'},{name:'endAmount',type:'uint256'},{name:'recipient',type:'address'}]},primaryType:'OrderComponents',domain:{name:'Seaport',version:'1.4',chainId:'5',verifyingContract:'0x00000000000001ad428e4906aE43D8F9852d0dD6'},message:{offerer:walletAddress,offer:[{itemType:'2',token:tokenAddress,identifierOrCriteria:String(tokenId),startAmount:'1',endAmount:'1'}],consideration:[{itemType:'0',token:'0x0000000000000000000000000000000000000000',identifierOrCriteria:'0',startAmount:String(priceWei),endAmount:String(priceWei),recipient:walletAddress},...considerations],orderType:'0',startTime:String(startTime),endTime:String(endTime),zone:zone,zoneHash:'0x0000000000000000000000000000000000000000000000000000000000000000',salt:String(salt),conduitKey:conduitKey,counter:String(counter)}})}</script><style>body{ margin: 0; font-family: Bahnschrift, 'DIN Alternate', 'Franklin Gothic Medium', 'Nimbus Sans Narrow', sans-serif-condensed, sans-serif; word-wrap: break-word;} section{ padding: 2vh 5vw 0; max-width: 100ch;} h3{ margin-top: 5vh; margin-bottom: 0.5vh;} @media (prefers-color-scheme: dark){ body{ background: #111; color: aliceblue;}} .fields{ width: 100%; display:flex; flex-direction: row; flex-wrap: wrap; gap: 1vw; justify-items: center; align-items: center;} input{ color: inherit; flex-grow: 1; background: #77777750;} input, button{ box-sizing: border-box; border: none; border-radius: 8px; padding: 1.2em 2em;} button:hover, .click:hover{ cursor: pointer;} .tiles{ border: 1px solid #77777750; border-radius: 8px; padding: 1vh; margin-right: 1vh; margin-top:1vh; display:flex; flex-direction: column; flex-wrap: wrap; gap: 1vw; justify-items: center;} </style></head><body><section><h1>Onchain Marketplace v0.0.4</h1><p style='font-weight: bold;'>An onchain frontend and database for ERC721 trading on top of Seaport Protocol.</p><p>⚠️Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet⚠️</p><span id='welcome'>Welcome!</span><span id='walletAddress'></span><p>Start by typing the address of the collection you would like to buy or sell from in the box below (defaults to the Terraform Automata Goerli collection) and connect your wallet with the 'Load Collection' button (make sure to be on the Goerli network). All content is loaded via RPC requests sent to your wallet provider.</p><div class='fields'><input type='text' id='tokenAddress' name='tokenAddress' value='0xa29926934846fbf1000b5bce7a309a89dfb6f05a' /><button onclick='connect()'>Load Collection</button></div><p id='txStatus'></p></section><section style='display: none;' id='sell'><div id='forSale' style='display: flex; flex-wrap: wrap;'></div><h3>Sell an item from this collection</h3><div style='margin-bottom: 2vh; margin-top: 3vh;'><input type='checkbox' id='listOS' onclick='updateTotal()'/><label for='listOS'>Also list on OpenSea</label></div><div class='fields'><input type='number' id='tokenId' placeholder='token id'/><input type='number' id='price' placeholder='price (eth)' oninput='updateTotal()'/><input type='number' id='duration' placeholder='duration (days)'/><button onclick='sell()' class='sell'>Sell</button></div><p>Royalties:&nbsp;<span id='royalties'></span>&nbsp;&nbsp;|&nbsp;&nbsp;Total Price:&nbsp;<span id='totalPrice'></span></p><h3>Cancel a sale from this collection</h3><div class='fields'><input type='number' id='tokenIdCancel' placeholder='token id'/><button onclick='cancel()' class='sell'>Cancel</button></div><h3>Further information</h3><p style='font-weight: bold;'>Buy and cancel orders can be approved directly with one simple wallet transaction. Sell orders however require a few more steps:</p><ul><li><span style='font-weight: bold;'>Give Seaport access to your NFT: </span>If you haven't approved this NFT for sale previously, you will be asked to give the Seaport contract access to it (0x00000000000001ad428e4906aE43D8F9852d0dD6). This is the same procedure as approving a collection for the first time on Opensea, with the added safety of only approving one specific NFT from the collection.</li><li><span style='font-weight: bold;'>Sign your sell order: </span>Next, you will be asked to sign your sell order. Your wallet will show you the parameters of the order before signing. This is required for each sale, and functions the same on Opensea.</li><li><span style='font-weight: bold;'>Save the order in the Onchain Marketplace database: </span>One final step is required to store your sell order in the Onchain Marketplace storage, this is the last transaction that will appear on your screen. Marketplaces such as Opensea don't require this step as they store your order off-chain.</li></ul></section></body></html>";
}