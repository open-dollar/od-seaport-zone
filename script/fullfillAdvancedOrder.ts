import {
    VAULT721_SEPOLIA_ADDRESS,
    VAULT721_SEPOLIA_ADAPTER_ADDRESS,
    // VAULT721_MAINNET_ADAPTER_ADDRESS,
    VAULT721_MAINNET_ADDRESS,
    SIP15_ZONE_SEPOLIA_ADDRESS,
    ARB_SEPOLIA_RPC,
    ARB_MAINNET_RPC,
    ARB_SEPOLIA_PK,
    ARB_MAINNET_PK,
    ENCODING_HELPER_SEPOLIA,
    // ENCODING_HELPER_MAINNET,
    Vault721AdapterABI,
    EncodeSubstandard5ForEthersABI
  } from "./utils/constants";

import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";
import { Seaport } from "@opensea/seaport-js";
import { Wallet, Provider } from "ethers";
import {
  Vault721Adapter,
  EncodeSubstandard5ForEthers,
} from "../types/ethers-contracts/index";


const fullfillSIP15ZoneListing = async (chain: string) => {}