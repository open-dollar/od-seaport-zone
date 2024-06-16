require("dotenv").config();
import fs from "fs";
import path from "path";
import { ethers, Wallet, Provider } from "ethers";
import { Seaport } from "@opensea/seaport-js";
import {
  Vault721Adapter,
  EncodeSubstandard5ForEthers,
  Vault721,
} from "../../types/ethers-contracts/index";
import {
  stringToObject,
  checkSepoliaAddress,
  checkMainnetAddress,
} from "./helpers";

const baseSepoliaPath = path.join(
  "node_modules/@opendollar/contracts/script/SepoliaContracts.s.sol"
);
const baseMainnetPath = path.join(
  "node_modules/@opendollar/contracts/script/MainnetContracts.s.sol"
);

const baseSepoliaDeploymentsPath = path.join(
  "broadcast/DeploySIP15Zone.s.sol/421614/run-latest.json"
);

/** @note uncomment next line when mainnet deployment has been done */
// const baseMainnetDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/42161/run-latest.json');

/** @note delete this next line when mainnet deployment is done */
const baseMainnetDeploymentsPath = path.join(
  "broadcast/DeploySIP15Zone.s.sol/31337/run-latest.json"
);
/** @note do the things said above */

const sepoliaContractsString: string = fs.readFileSync(
  baseSepoliaPath,
  "utf-8"
);
const mainnetContractsString: string = fs.readFileSync(
  baseMainnetPath,
  "utf-8"
);
const sepoliaDeployments = JSON.parse(
  fs.readFileSync(baseSepoliaDeploymentsPath, "utf-8")
);
const mainnetDeployments = JSON.parse(
  fs.readFileSync(baseMainnetDeploymentsPath, "utf-8")
);

const sepoliaContracts = stringToObject(sepoliaContractsString);
const mainnetContracts = stringToObject(mainnetContractsString);

export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
export const ARB_SEPOLIA_BUYER_PK = process.env.ARB_SEPOLIA_BUYER_PK;
export const ARB_SEPOLIA_OFFERER_PK = process.env.ARB_SEPOLIA_OFFERER_PK;
export const ARB_MAINNET_PK = process.env.ARB_MAINNET_PK;
export const ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
export const ARB_MAINNET_RPC = process.env.ARB_MAINNET_RPC;

//   export const SIP15_ZONE_MAINNET_ADDRESS = checkMainnetAddress(mainnetDeployments, 0)
export const SIP15_ZONE_SEPOLIA_ADDRESS = checkSepoliaAddress(
  sepoliaDeployments,
  0
);

export const VAULT721_SEPOLIA_ADAPTER_ADDRESS = checkSepoliaAddress(
  sepoliaDeployments,
  1
);

//   export const VAULT721_MAINNET_ADAPTER_ADDRESS = checkMainnetAddress(mainnetDeployments, 1)
export const VAULT721_SEPOLIA_ADDRESS = sepoliaContracts.Vault721_Address;
export const VAULT721_MAINNET_ADDRESS = mainnetContracts.Vault721_Address;
export const VAULT721_ANVIL_ADDRESS = process.env.VAULT721_ANVIL_ADDRESS;

//   export const ENCODING_HELPER_MAINNET = checkMainnetAddress(mainnetDeployments, 2)
export const ENCODING_HELPER_SEPOLIA = checkSepoliaAddress(
  sepoliaDeployments,
  2
);

export const Vault721AdapterABI = require("../../abis/Vault721Adapter.json");
export const EncodeSubstandard5ForEthersABI = require("../../abis/EncodeSubstandard5ForEthers.json");
export const Vault721ABI = require("../../abis/Vault721.json");
export const ERC20ABI = require("../../abis/ERC20.json");

export class Web3Environment {
  provider: Provider;
  wallet: Wallet;
  seaport: Seaport;
  encodeSubstandard5Helper: EncodeSubstandard5ForEthers | undefined;
  vault721AdapterAddress: string;
  vault721Address: string;
  sip15ZoneAddress: string;
  vault721Adapter: Vault721Adapter;
  vault721: Vault721;

  constructor(walletType: string, chain: string) {
    if (chain == "sepolia") {
      if (walletType == "offerer") {
        if (ARB_SEPOLIA_RPC && ARB_SEPOLIA_OFFERER_PK) {
          this.provider = new ethers.JsonRpcProvider(ARB_SEPOLIA_RPC);
          this.wallet = new ethers.Wallet(ARB_SEPOLIA_OFFERER_PK, this.provider);
          this.seaport = new Seaport(this.wallet);
        } else {
          throw new Error(".env VARS missing: ARB_SEPOLIA_RPC, ARB_SEPOLIA_PK");
        }
      } else {
        if (ARB_SEPOLIA_RPC && ARB_SEPOLIA_BUYER_PK) {
          this.provider = new ethers.JsonRpcProvider(ARB_SEPOLIA_RPC);
          this.wallet = new ethers.Wallet(ARB_SEPOLIA_BUYER_PK, this.provider);
          this.seaport = new Seaport(this.wallet);
        } else {
          throw new Error(".env VARS missing: ARB_SEPOLIA_RPC, ARB_SEPOLIA_PK");
        }
      }
      if (
        VAULT721_SEPOLIA_ADAPTER_ADDRESS &&
        SIP15_ZONE_SEPOLIA_ADDRESS &&
        VAULT721_SEPOLIA_ADDRESS
      ) {
        this.vault721AdapterAddress = VAULT721_SEPOLIA_ADAPTER_ADDRESS;
        this.vault721Address = VAULT721_SEPOLIA_ADDRESS;
        this.sip15ZoneAddress = SIP15_ZONE_SEPOLIA_ADDRESS;
      } else {
        throw new Error("VAULT721_SEPOLIA_ADAPTER_ADDRESS undefined");
      }
      // if no helper exists deploy helper
      if (!ENCODING_HELPER_SEPOLIA) {
        this.deployEncodingHelper();
      } else {
        this.encodeSubstandard5Helper = new ethers.Contract(
          ENCODING_HELPER_SEPOLIA,
          EncodeSubstandard5ForEthersABI.abi,
          this.wallet
        ) as unknown as EncodeSubstandard5ForEthers;
      }
      // } else if (chain == 'mainnet'){

      // if(ARB_MAINNET_RPC && ARB_MAINNET_PK){
      //   this.provider = new ethers.JsonRpcProvider(ARB_MAINNET_RPC);
      //   this.wallet = new ethers.Wallet(ARB_MAINNET_PK, this.provider);
      //   this.seaport = new Seaport(this.wallet);
      //   } else {
      //     throw new Error('.env VARS missing: ARB_MAINNET_RPC, ARB_MAINNET_PK')
      //   }

      //   if (VAULT721_MAINNET_ADAPTER_ADDRESS && VAULT721_MAINNET_ADDRESS) {
      //     vault721AdapterAddress = VAULT721_MAINNET_ADAPTER_ADDRESS;
      //     vault721Address = VAULT721_MAINNET_ADDRESS;
      //   } else {
      //     throw new Error("VAULT721_MAINNET_ADAPTER_ADDRESS undefined");
      //   }

      //   // if no helper exists deploy helper
      // this.deployEncodingHelper();
      //   } else {
      //     encodeSubstandard5Helper = new ethers.Contract(
      //       ENCODING_HELPER_MAINNET,
      //       EncodeSubstandard5ForEthersABI.abi,
      //       wallet
      //     ) as unknown as EncodeSubstandard5ForEthers;
      //   }
    } else {
      throw new Error("unsupported chain");
    }

    this.vault721Adapter = new ethers.Contract(
      this.vault721AdapterAddress,
      Vault721AdapterABI.abi,
      this.wallet
    ) as unknown as Vault721Adapter;

    this.vault721 = new ethers.Contract(
      this.vault721Address,
      Vault721ABI.abi,
      this.wallet
    ) as unknown as Vault721;
  }

  async deployEncodingHelper() {
    const encodeSubstandard5Factory = new ethers.ContractFactory(
      EncodeSubstandard5ForEthersABI.abi,
      EncodeSubstandard5ForEthersABI.bytecode,
      this.wallet
    );
    this.encodeSubstandard5Helper =
      (await encodeSubstandard5Factory.deploy()) as EncodeSubstandard5ForEthers;
  }
}
