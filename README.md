<p align="center">
<img width="60" height="60"  src="https://raw.githubusercontent.com/open-dollar/.github/main/od-logo.svg">
</p>
<h1 align="center">
  Open Dollar
</h1>

<p align="center">
  <a href="https://twitter.com/open_dollar" target="_blank">
    <img alt="Twitter: open_dollar" src="https://img.shields.io/twitter/follow/open_dollar.svg?style=social" />
  </a>
</p>

# Dynamic Traits Enforcement Zone

A Seaport zone which implements [ERC-7496](https://eips.ethereum.org/EIPS/eip-7496) to enforce NFT trait details.

The zone was developed to align with the [SIP-15](https://github.com/open-dollar/SIPs/blob/main/SIPS/sip-15.md) standard from Seaport.

## Setup

Use the command-line scripts to create, submit, and fulfill an order for an Open Dollar NFV, using the OpenSea API.

1. Copy the `.env.example` and update the following values:

```bash
ARB_SEPOLIA_RPC=

ARB_SEPOLIA_OFFERER_PK=
ARB_SEPOLIA_BUYER_PK=
```

2. Use the “Offerer” wallet to open a vault on Open Dollar testnet https://app.dev.opendollar.com

3. User the “Buyer” wallet to mint the consideration token "ARB" at https://sepolia.arbiscan.io/address/0x3018EC2AD556f28d2c0665d10b55ebfa469fD749#writeContract

## Create Listing

Use the `create-listing` scrip to create an order from the "Offerer" wallet.

```bash
# Install and build the contracts
yarn
yarn build

yarn create-listing <chainName> <tokenId> <considerationAmountInEther>
# eg.
yarn create-listing sepolia 313 0.000001
```

## Fulfill Order

Use the fulfill script to execute the order from the "Buyer" wallet.

```bash
yarn fulfill <chainName> <orderPath>
# eg. 
yarn fulfill sepolia orders/order-1-1718667016.json
```

Important Notes:

- On testnet, Open Dollar NFVs have a 100 second cooldown after any modification before they can be transferred.
- The default order `endTime` is currently 24 hours.
