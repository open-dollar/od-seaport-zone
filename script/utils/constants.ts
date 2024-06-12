require("dotenv").config();
import fs from "fs";
import path from "path";
import { BigNumberish, BytesLike, ethers, Wallet, Provider } from "ethers";
import { Seaport } from "@opensea/seaport-js";
import {
  Vault721Adapter,
  EncodeSubstandard5ForEthers,
} from "../../types/ethers-contracts/index";

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

type ParsedObjectType = {
  [key: string]: string;
};

function stringToObject(str: string): ParsedObjectType {
  const parts = str.split(";");
  const trimmedObject: ParsedObjectType = {};
  parts
    .filter((element, i) => {
      return element.includes("=");
    })
    .forEach((e, i) => {
      const searchString = "address public";
      const thing = e.indexOf(searchString);
      const [key, value] = e
        .trim()
        .slice(thing + 12)
        .split("=");
      const trimmedKey = key.trim().replace(/^address\s+/, "");
      const trimmedValue = value.trim().replace(/;$/, "");
      trimmedObject[trimmedKey] = trimmedValue;
    });
  return trimmedObject;
}

export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
export const ARB_SEPOLIA_PK = process.env.ARB_SEPOLIA_PK;
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

export const Vault721AdapterABI = require("../../out/Vault721Adapter.sol/Vault721Adapter.json");
export const EncodeSubstandard5ForEthersABI = require("../../out/EncodeSubstandard5ForEthers.sol/EncodeSubstandard5ForEthers.json");

export class Web3Environment {
  provider: Provider;
  wallet: Wallet;
  seaport: Seaport;
  encodeSubstandard5Helper: EncodeSubstandard5ForEthers | undefined;
  vault721AdapterAddress: string;
  vault721Address: string;
  sip15ZoneAddress: string;
  vault721Adapter:Vault721Adapter;

  constructor(chain:string){
    if (chain == "sepolia") {
      this.provider = new ethers.JsonRpcProvider(ARB_SEPOLIA_RPC);
      this.wallet = new ethers.Wallet(ARB_SEPOLIA_PK as string, this.provider);
      this.seaport = new Seaport(this.wallet);
  
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
      //   provider = new ethers.JsonRpcProvider(ARB_MAINNET_RPC);
      //   wallet = new ethers.Wallet(ARB_MAINNET_PK as string, provider);
      //   seaport = new Seaport(wallet);
  
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
  
  }

  async deployEncodingHelper(){
    const encodeSubstandard5Factory = new ethers.ContractFactory(
      EncodeSubstandard5ForEthersABI.abi,
      EncodeSubstandard5ForEthersABI.bytecode,
      this.wallet
    );
    this.encodeSubstandard5Helper =
      (await encodeSubstandard5Factory.deploy()) as EncodeSubstandard5ForEthers;
  }

}

function checkMainnetAddress(
  deployment: any,
  index: number
): string | undefined {
  return (() => {
    try {
      return deployment.receipts[index].contractAddress;
    } catch (error) {
      if (index == 0 && process.env.SIP15_ZONE_MAINNET_ADDRESS) {
        return process.env.SIP15_ZONE_MAINNET_ADDRESS;
      } else if (index == 1 && process.env.VAULT721_MAINNET_ADAPTER_ADDRESS) {
        return process.env.VAULT721_MAINNET_ADAPTER_ADDRESS;
      } else if (index == 2 && process.env.ENCODING_HELPER_MAINNET) {
        return process.env.ENCODING_HELPER_MAINNET;
      } else {
        console.error(error);
      }
    }
  })();
}

function checkSepoliaAddress(
  deployment: any,
  index: number
): string | undefined {
  return (() => {
    try {
      return deployment.receipts[index].contractAddress;
    } catch (error) {
      if (index == 0 && process.env.SIP15_ZONE_SEPOLIA_ADDRESS) {
        return process.env.SIP15_ZONE_SEPOLIA_ADDRESS;
      } else if (index == 1 && process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS) {
        return process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS;
      } else if (index == 2 && process.env.ENCODING_HELPER_SEPOLIA) {
        return process.env.ENCODING_HELPER_SEPOLIA;
      } else {
        console.error(error);
        throw new Error("addresses cannot be gotten");
      }
    }
  })();
}
