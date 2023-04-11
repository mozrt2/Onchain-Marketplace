# Changelog

## [0.0.4] - 2023-04-11
Focused on new features enabling automatic [EIP2981](https://eips.ethereum.org/EIPS/eip-2981) royalty payments and listing on OpenSea

- **Royalties**:
    - **multiple considerations**: a sell order can now contain more than one consideration. All considerations will be stored in the OM database. This enables royalty payments.
    - **EIP2981 royalty check**: the frontend automatically check if a collection has enabled royalties following EIP2981. If yes, the royalty payment is automatically added to a sell order. 

- **OpenSea listing**:
    - **OpenSea-compatible order generation**: when the signature of an order compatible with OpenSea is added at the end of the parameters in `sell()`, the function automatically generates and validates a second order compatible with OS' requirements (i.e. 2.5% OS fee), thereby automatically listing the order on OS. Note: while this feature should work in theory, it cannot be tested on Goerli as OS is not indexing validated orders on Goerli.
    - **list on OpenSea checkbox**: in the frontend, users can tick a box when selling an item to also list it on OpenSea. This creates two orders (it is therefore more gas costly): an order for Onchain Marketplace without any additional fees and an order for OpenSea with OS' mandatory fee.

- **Constructor variables**:
    - the following variables used both in the frontend and backend can now be set inside the constructor:
        - `_seaportAddress`: Seaport contract address
        - `_openseaAddress`: Opensea contract address, for fee payment
        - `_openseaFee`: the fee charged by Opensea for a sale of 1 ETH
        - `_openseaConduitKey`: the key for the Opensea conduit
        - `_defaultCollection`: the default NFT collection for the frontend

- **Storage variables**:
    - amount is now stored as a uint64 instead of uint32 to allow for a larger range of prices (between 18.4k ETH and 1000 Wei) while not significantly impacting gas

## [0.0.3] - 2023-04-01
Focused on new frontend features for improved UX

- Backend:
    - added the read function `getOrderStatus()` to MarketMap.sol: it queries the order status from Seaport to ensure it is still a valid order (i.e. has not been sold, cancelled or transferred without updating Onchain Marketplace's database).

- Frontend:
    - friendlier UI contributed by [@sameoldlab](https://github.com/sameoldlab)
    - `sign()` function now queries Seaport's `getCounter()` to enable users with a counter over 0 to sell their items
    - tiles are only generated for an item when `getOrderStatus()` returns `true` (i.e. the order is still valid)
    - transaction status and hash are now shown to users 
    - `sell()` transaction now only gets triggered once the `approve()` transaction is successfully processed
    - `tokenURI()` data fetched from a collection's ERC721 contract and added to each tile:
        - `image` and `name` on the tile itself
        - `animation_url` pops-up when clicking on the tile title or image 
        - `attributes` pops-up when clicking on "🛈" 


## [0.0.2] - 2023-03-25
Focused on optimizing gas and simplifying the code

- Optimized order parameter storage (`UniqueOrderParameters`) to reduce gas costs:
    - Gas costs v0.0.2 vs v0.0.1:
        - `sell()`: 222,000 vs 312,000 (-29%)
        - `buy()`: 110,000 vs 159,000 (-31%)
        - `cancelOrder()`: 66,000 vs 100,000 (-34%)
    - Changes:
        - `offerer` is not stored anymore: the owner of the NFT is retrieved by calling `ownerOf()` in the NFT contract when composing an order (-7% gas)
        - `startTime`, `endTime`, and `amount` are stored as uint32 and `salt` is stored as uint16 instead of uint256: the range of these numbers remains practical enough to cover all use cases and require functions are used to ensure user input does not over/underflow (-12% gas)
        - `signature` is broken into three components for storage, `vSignature`, `rSignature`, `sSignature` in bytes1, bytes32, and bytes32 formats respectively: the full signature is recomposed when composing an order (-15% gas)
    - Comparison with other marketplaces: see [README.md](https://github.com/mozrt2/Onchain-Marketplace#readme)

- `sell()` function: replaced read call to `validateOfferItems()` from [Seaport Validator](https://goerli.etherscan.io/address/0xF75194740067D6E4000000003b350688DD770000) with write call to `validate()` from [Seaport](https://goerli.etherscan.io/address/0x00000000000001ad428e4906ae43d8f9852d0dd6) in order to:
    - validate the full order, including its signature
    - trigger an event from the Seaport contract, which should automatically list the offer on Opensea (and thereby also Blur) on Mainnet: this needs to be confirmed as it does not trigger on Goerli testnet 

- Refactored the JavaScript in the frontend HTML to simplify it and make it lighter (reduced size by ~10%)

- Added annotations on both the solidity files and the fronted HTML

