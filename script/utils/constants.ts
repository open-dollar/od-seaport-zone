import { JsonRpcProvider, ethers } from "ethers";
require('dotenv').config();

export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
export const WALLET_PRIV_KEY = process.env.ARB_SEPOLIA_PK;
export const ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
export const SIP15_ZONE_SEPOLIA_ADDRESS = process.env.SIP15_ZONE_SEPOLIA_ADDRESS;
export const SIP15_ZONE_ANVIL_ADDRESS = process.env.SIP15_ZONE_ANVIL_ADDRESS;
export const VAULT721_SEPOLIA_ADAPATER_ADDRESS = process.env.VAULT721_SEPOLIA_ADAPATER_ADDRESS;
export const VAULT721_ANVIL_ADAPATER_ADDRESS = process.env.VAULT721_ANVIL_ADAPATER_ADDRESS;
export const VAULT721_SEPOLIA_ADDRESS = process.env.VAULT721_SEPOLIA_ADDRESS;
export const VAULT721_ANVIL_ADDRESS = process.env.VAULT721_ANVIL_ADDRESS;
export const ANVIL_ONE = process.env.ANVIL_ONE;
export const ANVIL_RPC = process.env.ANVIL_RPC;
export const ENCODING_HELPER = process.env.ENCODING_HELPER;
export const ENCODING_HELPER_ANVIL = process.env.ENCODING_HELPER_ANVIL;
export const sepoliaProvider = new JsonRpcProvider(ARB_SEPOLIA_RPC);

export const sepoliaWallet = new ethers.Wallet(
    WALLET_PRIV_KEY as string,
    sepoliaProvider
);

export const SEPOLIA_WALLET_ADDRESS = sepoliaWallet.address;

