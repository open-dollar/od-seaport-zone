require('dotenv').config();

import { AddressLike } from "ethers";
import fs from "fs";
import path from "path";


const baseSepoliaPath = path.join('node_modules/@opendollar/contracts/script/SepoliaContracts.s.sol');
const baseMainnetPath = path.join('node_modules/@opendollar/contracts/script/MainnetContracts.s.sol');
const baseAnvilDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/31337/run-latest.json');
const baseSepoliaDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/421614/run-latest.json');

/** @note uncomment next line when mainnet deployment is done */
// const baseMainnetDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/42161/run-latest.json');

/** @note delete this next line when mainnet deployment is done */
const baseMainnetDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/31337/run-latest.json');
/** @note do the things said above */

const sepoliaContractsString: string = fs.readFileSync(baseSepoliaPath, 'utf-8');
const mainnetContractsString: string = fs.readFileSync(baseMainnetPath, 'utf-8');
const anvilDeployments = JSON.parse(fs.readFileSync(baseAnvilDeploymentsPath, 'utf-8'));
const sepoliaDeployments = JSON.parse(fs.readFileSync(baseSepoliaDeploymentsPath, 'utf-8'));
const mainnetDeployments = JSON.parse(fs.readFileSync(baseMainnetDeploymentsPath, 'utf-8'));

const sepoliaContracts = stringToObject(sepoliaContractsString);
const mainnetContracts = stringToObject(mainnetContractsString);


type ParsedObjectType = {
    [key: string]: string;
}

function stringToObject(str: string): ParsedObjectType{
    const parts = str.split(';');
    const trimmedObject: ParsedObjectType = {};
    parts.filter((element, i ) => {
        return element.includes('=');
    }).forEach((e,i) => {
        const searchString = 'address public';
        const thing = e.indexOf(searchString);
        const [key, value] = e.trim().slice(thing + 12).split('=');
        const trimmedKey = key.trim().replace(/^address\s+/, '');
        const trimmedValue = value.trim().replace(/;$/, '');
        trimmedObject[trimmedKey] = trimmedValue;
    });
    return trimmedObject;
  }


  export const OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
  export const ARB_SEPOLIA_PK = process.env.ARB_SEPOLIA_PK;
  export const ARB_MAINNET_PK = process.env.ARB_MAINNET_PK;
  export const ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
  export const ARB_MAINNET_RPC = process.env.ARB_MAINNET_RPC;
  export const ANVIL_ONE = process.env.ANVIL_ONE;
  export const ANVIL_RPC = process.env.ANVIL_RPC;

//   export const SIP15_ZONE_MAINNET_ADDRESS = mainnetDeployments.receipts[0].contractAddress
  export const SIP15_ZONE_SEPOLIA_ADDRESS = sepoliaDeployments.receipts[0].contractAddress
  export const SIP15_ZONE_ANVIL_ADDRESS = anvilDeployments.receipts[0].contractAddress;

  export const VAULT721_SEPOLIA_ADAPTER_ADDRESS = sepoliaDeployments.receipts[1].contractAddress
  export const VAULT721_ANVIL_ADAPTER_ADDRESS = anvilDeployments.receipts[1].contractAddress;
//   export const VAULT721_MAINNET_ADAPTER_ADDRESS = mainnetDeployments.receipts[1].contractAddress
  export const VAULT721_SEPOLIA_ADDRESS = sepoliaContracts.Vault721_Address;
  export const VAULT721_MAINNET_ADDRESS = mainnetContracts.Vault721_Address;
  export const VAULT721_ANVIL_ADDRESS = process.env.VAULT721_ANVIL_ADDRESS;

//   export const ENCODING_HELPER_MAINNET = mainnetDeployments.receipts[2].contractAddress
  export const ENCODING_HELPER_SEPOLIA = sepoliaDeployments.receipts[2].contractAddress
  export const ENCODING_HELPER_ANVIL = anvilDeployments.receipts[2].contractAddress;
  
  function checkMainnetAddress(deployment: any, index: number): AddressLike | undefined{
    return (() => {
        try {
           return deployment.receipts[index].contractAddress
        } catch(error){
            if(index == 0 && process.env.SIP15_ZONE_MAINNET_ADDRESS){
                return process.env.SIP15_ZONE_MAINNET_ADDRESS;
            } else if (index == 1 && process.env.VAULT721_MAINNET_ADAPTER_ADDRESS){
                return process.env.VAULT721_MAINNET_ADAPTER_ADDRESS;
            } else if (index == 2 && process.env.ENCODING_HELPER_MAINNET){
                return process.env.ENCODING_HELPER_MAINNET;
            } else {
                console.error(error);
            }
        }
    })();
  }

  function checkSepoliaAddress(deployment: any, index: number): AddressLike | undefined{
    return(() => {
        try {
            return deployment.receipts[index].contractAddress
        } catch(error){
            if(index == 0 && process.env.SIP15_ZONE_SEPOLIA_ADDRESS){
                return process.env.SIP15_ZONE_SEPOLIA_ADDRESS;
            } else if (index == 1 && process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS){
                return process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS;
            } else if (index == 2 && process.env.ENCODING_HELPER_SEPOLIA){
                return process.env.ENCODING_HELPER_SEPOLIA;
            } else {
                console.error(error);
                throw new Error('addresses cannot be gotten');
            }
        }
    })();
  }