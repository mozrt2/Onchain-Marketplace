# Onchain Marketplace
An onchain frontend and database for ERC721 trading built on top of the [Seaport Protocol](https://github.com/ProjectOpenSea/seaport)

⚠️**Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet**⚠️

## Introduction

[Onchain Marketplace](https://goerli.etherscan.io/address/0x03dd842df1fa02fa70995998c7018c3e22b3c1e6) allows users to:
- Put ERC721 tokens (NFTs) up for sale within an onchain contract (contrary to e.g. Opensea, the full data of an order is stored and can be retrieved onchain)
- Buy ERC721 tokens that are for sale on the onchain contract
- Cancel the sale of an item

Users can either use the Onchain Marketplace frontend and a wallet extension via the html() read function in Storefront.sol or interact directly with the backend via the sell(), buy(), and cancelOrder() write functions in MarketMap.sol. 

All trades are made through the Seaport contract and sellers are only required to give NFT transfer access to [Seaport](https://goerli.etherscan.io/address/0x00000000000001ad428e4906ae43d8f9852d0dd6), **the Onchain Marketplace contract does not have access to NFTs listed for sale**.

For the full user experience, it is recommended to query the html() function through the [evm-browser](https://github.com/nand2/evm-browser) using the [frame.sh wallet](https://frame.sh/) at `evm://0x03dd842df1fa02fa70995998c7018c3e22b3c1e6.5/call/html`.

To test without having to set up anything else, you can use the off-chain version [here](https://onchainmarketplace.mozrt.repl.co/v002.html) with a browser wallet such as Metamask (all interactions on the page are still queried onchain). 

## Overview

Onchain Marketplace is composed of 3 Solidity files:
- [**MarketInterface.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketInterface.sol): contains all structs, enums, and functions to interact with the Seaport contract
- [**MarketMap.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketMap.sol): Onchain Marketplace's backend, storing and managing all sell, buy and cancel orders
- [**OnchainMarketplace.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/Storefront.sol) (formerly Storefront.sol): an html file stored onchain that enables users to interact with the Onchain Marketplace through their browsers - it doesn't use any external libraries & resources and interacts with the Ethereum network through RPC requests to a user's wallet (I learnt a lot about calldata this week :) )

## Tested environments

- Onchain HTML in evm-browser with Frame.sh
- Offchain HTML in Brave browser with Metamask

## Changelog & To-dos

Onchain Marketplace is an early proof of concept. Below is a list of improvement items ranked by order of importance. You can find the [**changelog here**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/CHANGELOG.md). 

### Audit

Thorough review of the entire code to ensure users can safely interact with (1) the contracts directly and (2) the onchain frontend. Third party reviews and tests would be greatly appreciated.

### Gas Optimization

Gas cost improvement for all write functions was the focus of Onchain Marketplace (OM) v0.0.2. Below is an overview of current gas costs compared with previous versions and alternatives.

|                | **OM v0.0.2**   | OM v0.0.1       | Seaport v1.4*   | Zora Asks v1.1  | Manifold        |
| -------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| Sell           | **222,000**     | 312,000         | off-chain       | 117,000         | 243,000         |
| Buy            | **110,000**     | 159,000         | 130,000         | 148,000         | 142,000         |
| Cancel         | **66,000**      | 100,000         | 29,000          | 43,000          | 92,000          |

*Seaport does not store orders onchain, thereby reducing gas across all transaction types. Seaport's buy function tends to be more costly than Onchain Marketplace's as most orders use a conduit and transfer a fee to it. 

### Additional Features

Frontend:
- Ensure Seaport's counter is queried to ensure all users can post sell orders
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
