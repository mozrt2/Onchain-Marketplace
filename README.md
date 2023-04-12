# Onchain Marketplace
An onchain frontend and database for ERC721 trading built on top of the [Seaport Protocol](https://github.com/ProjectOpenSea/seaport)

⚠️**Onchain Marketplace is in alpha, do not interact with the contract with any valuable wallets or NFTs and only use on Goerli testnet**⚠️

## Introduction

[Onchain Marketplace](https://goerli.etherscan.io/address/0x6d46faf7764d16133dce5342465d8b8e85e9c24f) allows users to:
- Put ERC721 tokens (NFTs) up for sale within an onchain contract (contrary to e.g. Opensea, the full data of an order is stored and can be retrieved onchain)
- Buy ERC721 tokens that are for sale on the onchain contract
- Cancel the sale of an item

Users can either use the Onchain Marketplace frontend and a wallet extension via the html() read function in OnchainMarketplace.sol or interact directly with the backend via the sell(), buy(), and cancelOrder() write functions in MarketMap.sol. 

All trades are made through the Seaport contract and sellers are only required to give NFT transfer access to [Seaport](https://goerli.etherscan.io/address/0x00000000000001ad428e4906ae43d8f9852d0dd6), **the Onchain Marketplace contract does not have access to NFTs listed for sale**.

For the full user experience, it is recommended to query the html() function through the [evm-browser](https://github.com/nand2/evm-browser) using the [frame.sh wallet](https://frame.sh/) at `web3://0x6d46faf7764d16133dce5342465d8b8e85e9c24f:5/html`.

To test without having to set up anything else, you can use [w3link.io at this link](https://0x6d46faf7764d16133dce5342465d8b8e85e9c24f.gor.w3link.io/html) with a browser wallet such as Metamask (all interactions on the page are still queried onchain). 

## Overview

Onchain Marketplace is composed of 3 Solidity files:
- [**MarketInterface.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketInterface.sol): contains all structs, enums, and functions to interact with the Seaport contract
- [**MarketMap.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/MarketMap.sol): Onchain Marketplace's backend, storing and managing all sell, buy and cancel orders
- [**OnchainMarketplace.sol**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/foundry/src/OnchainMarketplace.sol) (formerly Storefront.sol): an html file stored onchain that enables users to interact with the Onchain Marketplace through their browsers - it doesn't use any external libraries & resources and interacts with the Ethereum network through RPC requests to a user's wallet.

## Tested environments

- Onchain HTML in evm-browser with Frame.sh
- Offchain HTML in Brave browser with Metamask

## Changelog & To-dos

Onchain Marketplace is an early proof of concept. Below is a list of improvement items ranked by order of importance. You can find the [**changelog here**](https://github.com/mozrt2/Onchain-Marketplace/blob/main/CHANGELOG.md). 

### Audit

Thorough review of the entire code to ensure users can safely interact with (1) the contracts directly and (2) the onchain frontend. Third party reviews and tests would be greatly appreciated.

### Gas Optimization

Gas usage improvement for all write functions was the focus of Onchain Marketplace (OM) v0.0.2. Below is an overview of current gas usage compared with previous versions and alternatives.

|                | **OM v0.0.4****           | OM v0.0.2       | OM v0.0.1       | Seaport v1.4*   | Zora Asks v1.1  | Manifold        |
| -------------- | ------------------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| Sell           | **223k (234k/252k/300k)** | 222k            | 312k            | off-chain       | 117k            | 243k            |
| Buy            | **112k (140k)**           | 110k            | 159k            | 130k            | 148k            | 142k            |
| Cancel         | **69k (73k)**             | 66k             | 100k            | 29k             | 43k             | 92k             |

*Seaport does not store orders onchain, thereby reducing gas across all transaction types. Seaport's buy function tends to be more costly than Onchain Marketplace's as most orders use a conduit and transfer a fee to it. 
**Gas usage varies depending on parameters, see values in brackets:
- Sell: without royalties, no OpenSea listing (with royalties, no OS listing / without royalties, incl. OS listing / with royalties, incl. OS listing)
- Buy / Cancel: without royalties (with royalties)

### New Features 

General:
- Modularize Onchain Marketplace: break OM into smaller modules for flexible use. Potential use cases:
    - allow for an ERC721 contract extension (i.e. similar to ownable.sol, there could be a tradable.sol extension allowing users to trade their NFTs directly from the contract): this could be implemented alongside contract-enforced royalty options
    - update variables such as the Seaport address to migrate to a newer version of Seaport without having to redeploy everything
    - update the frontend while retaining the same database

Frontend:
- Verify inputs and give hints to ensure the input is valid
- Optimize html file size
- Add tile ordering options
- Adjust UI to be less text-heavy
- Add an optional input for the `html()` function to change the default collection displayed by the frontend

Backend:
- Enable more sale types: bulk sales, ERC1155 sales, ERC20 payments, decreasing/increasing prices, auctions, etc. 


~
reach out at hey@moritz.ooo for any queries related to this project
