import { ItemType, Seaport } from "@opensea/seaport-js";
import { JsonRpcProvider, ethers } from "ethers";

export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
export const WALLET_PRIV_KEY = process.env.ARB_SEPOLIA_PK;
export const ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
export const SIP15_ZONE_SEPOLIA_ADDRESS = process.env.SIP15_ZONE_SEPOLIA_ADDRESS;
export const VAULT721_SEPOLIA_ADAPATER_ADDRESS = process.env.VAULT721_SEPOLIA_ADAPATER_ADDRESS;
export const VAULT721_SEPOLIA_ADDRESS = process.env.VAULT721_SEPOLIA_ADDRESS;

let provider = new JsonRpcProvider(ARB_SEPOLIA_RPC);

export const wallet = new ethers.Wallet(
    WALLET_PRIV_KEY as string,
    provider
);

export const WALLET_ADDRESS = wallet.address;

export const seaport = new Seaport(wallet);