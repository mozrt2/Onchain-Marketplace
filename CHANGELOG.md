# Changelog

## [0.0.2] - 2023-03-25
Focused on optimizing gas and simplifying the code

### Changed

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

