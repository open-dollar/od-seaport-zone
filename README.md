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

A Seaport zone for specifying and enforcing values of ERC-7496 Dynamic Traits

View the SIP-15 standard: https://github.com/open-dollar/SIPs/blob/main/SIPS/sip-15.md

## Setup

1. Copy the `.env.example` and update the following values: 

```bash
ARB_SEPOLIA_RPC=

ARB_SEPOLIA_OFFERER_PK=
ARB_SEPOLIA_BUYER_PK=
```

2. Use the “Offerer” wallet to open a vault on Open Dollar testnet https://app.dev.opendollar.com 

2. User the “Buyer” wallet to mint the consideration token "ARB" at https://sepolia.arbiscan.io/address/0x3018EC2AD556f28d2c0665d10b55ebfa469fD749#writeContract


## Create listing

```bash
yarn 
yarn build

# Create Listing
yarn create-listing <chainName> <tokenId> <considerationAmountInEther>
yarn create-listing sepolia 313 0.000001 

# Execute listing 
yarn fulfill <chainName> <orderPath>
yarn fulfill sepolia orders/order-1-1718667016.json
```

Notes:
- Vaults have a 100 second cooldown on testnet before they can be transferred.
- Order `endTime` is 24 hours
