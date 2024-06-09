import { Chain, OpenSeaSDK } from "opensea-js";
import { JsonRpcProvider, ethers } from "ethers";

export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
export const WALLET_PRIV_KEY = process.env.WALLET_PRIV_KEY;
export const ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
export const SIP15_ZONE_ADDRESS = process.env.SIP15_ZONE_ADDRESS;
export const VAULT712_ADAPATER_ADDRESS = process.env.VAULT712_ADAPATER_ADDRESS;
export const VAULT712_ADDRESS = process.env.VAULT712_ADDRESS;

let provider = new JsonRpcProvider(ARB_SEPOLIA_RPC);

export const wallet = new ethers.Wallet(
    WALLET_PRIV_KEY as string,
    provider
);

export const WALLET_ADDRESS = wallet.address;

export const sdk = new OpenSeaSDK(
    wallet,
    {
        chain: Chain.ArbitrumSepolia,
        apiKey: OPENSEA_API_KEY,
    },
    (line) => console.info(`MAINNET: ${line}`),
);