# Onchain Marketplace
An onchain frontend and database for ERC721 trading built on top of the [Seaport Protocol](https://github.com/ProjectOpenSea/seaport)

⚠️**Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet**⚠️

## Introduction

[Onchain Marketplace](https://goerli.etherscan.io/address/0x94c513807f9eac865041e96a326b3e222965b0eb#readContract) allows users to:
- Put ERC721 tokens (NFTs) up for sale within an onchain contract (contrary to e.g. Opensea, the full data of an order is stored and can be retrieved onchain)
- Buy ERC721 tokens that are for sale on the onchain contract
- Cancel the sale of an item

Users can either use the Onchain Marketplace frontend and a wallet extension via the html() read function in Storefront.sol or interact directly with the backend via the sell(), buy(), and cancelOrder() write functions in MarketMap.sol. 

All trades are made through the Seaport contract and sellers are only required to give NFT transfer access to [Seaport](https://goerli.etherscan.io/address/0x00000000000001ad428e4906ae43d8f9852d0dd6), **the Onchain Marketplace contract does not have access to NFTs listed for sale**.

For the full user experience, it is recommended to query the html() function through the [evm-browser](https://github.com/nand2/evm-browser) using the [frame.sh wallet](https://frame.sh/) at `evm://0x94C513807f9eAC865041e96A326b3E222965b0eB.5/call/html`.

To test without having to set up anything else, you can use the off-chain version [here](https://onchainmarketplace.mozrt.repl.co/) with a browser wallet such as Metamask (all interactions on the page are still queried onchain). 

## Overview

Onchain Marketplace is composed of 3 Solidity files:
- [**MarketInterface.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketInterface.sol): contains all structs, enums, and functions to interact with the Seaport contract
- [**MarketMap.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketMap.sol): Onchain Marketplace's backend, storing and managing all sell, buy and cancel orders
- [**OnchainMarketplace.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/Storefront.sol) (formerly Storefront.sol): an html file stored onchain that enables users to interact with the Onchain Marketplace through their browsers - it doesn't use any external libraries & resources and interacts with the Ethereum network through RPC requests to a user's wallet (I learnt a lot about calldata this week :) )

## Tested environments

- Onchain HTML in evm-browser with Frame.sh
- Offchain HTML in Brave browser with Metamask

## To-dos

Onchain Marketplace is an early proof of concept. Below is a list of improvement items ranked by order of importance. 

### Audit

Thorough review of the entire code to ensure users can safely interact with (1) the contracts directly and (2) the onchain frontend. Third party reviews and tests would be greatly appreciated.

### Optimization

Gas cost improvement for all write functions: the greatest opportunity for improvement is most likely storage management, i.e. how sell orders are stored and managed. This is also the greatest downside of using Onchain Marketplace - selling an item costs ~300k gas and buying ~150k gas, much more than for off-chain solutions

### Additional Features

Frontend:
- Ensure Seaport's counter is queried so users can repost the same sale they cancelled previously
- Show transaction hash and status 
- Wait until the first sell transaction is confirmed to trigger the next one
- Load data from TokenURI to show an NFT's preview image, attributes & co. 
- Create a detail view which shows one specific NFT, including the full media
- Show all NFTs from a collection, not only those for sale on Onchain Marketplace
- Verify inputs and give hints to ensure the input is valid
- Create a user friendly UI while keeping CSS to a minimum

Backend:
- Enable more sale types: bulk sales, ERC1155 sales, ERC20 payments, decreasing/increasing prices, auctions, etc. 


~
reach out at hey@moritz.ooo for any queries related to this project
