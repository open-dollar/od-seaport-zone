"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Web3Environment = exports.ERC20ABI = exports.Vault721ABI = exports.EncodeSubstandard5ForEthersABI = exports.Vault721AdapterABI = exports.ENCODING_HELPER_SEPOLIA = exports.VAULT721_ANVIL_ADDRESS = exports.VAULT721_MAINNET_ADDRESS = exports.VAULT721_SEPOLIA_ADDRESS = exports.VAULT721_SEPOLIA_ADAPTER_ADDRESS = exports.SIP15_ZONE_SEPOLIA_ADDRESS = exports.ARB_MAINNET_RPC = exports.ARB_SEPOLIA_RPC = exports.ARB_MAINNET_PK = exports.ARB_SEPOLIA_PK2 = exports.ARB_SEPOLIA_PK1 = exports.OPENSEA_API_KEY = void 0;
require("dotenv").config();
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const ethers_1 = require("ethers");
const seaport_js_1 = require("@opensea/seaport-js");
const helpers_1 = require("./helpers");
const baseSepoliaPath = path_1.default.join("node_modules/@opendollar/contracts/script/SepoliaContracts.s.sol");
const baseMainnetPath = path_1.default.join("node_modules/@opendollar/contracts/script/MainnetContracts.s.sol");
const baseSepoliaDeploymentsPath = path_1.default.join("broadcast/DeploySIP15Zone.s.sol/421614/run-latest.json");
/** @note uncomment next line when mainnet deployment has been done */
// const baseMainnetDeploymentsPath = path.join('broadcast/DeploySIP15Zone.s.sol/42161/run-latest.json');
/** @note delete this next line when mainnet deployment is done */
const baseMainnetDeploymentsPath = path_1.default.join("broadcast/DeploySIP15Zone.s.sol/31337/run-latest.json");
/** @note do the things said above */
const sepoliaContractsString = fs_1.default.readFileSync(baseSepoliaPath, "utf-8");
const mainnetContractsString = fs_1.default.readFileSync(baseMainnetPath, "utf-8");
const sepoliaDeployments = JSON.parse(fs_1.default.readFileSync(baseSepoliaDeploymentsPath, "utf-8"));
const mainnetDeployments = JSON.parse(fs_1.default.readFileSync(baseMainnetDeploymentsPath, "utf-8"));
const sepoliaContracts = (0, helpers_1.stringToObject)(sepoliaContractsString);
const mainnetContracts = (0, helpers_1.stringToObject)(mainnetContractsString);
exports.OPENSEA_API_KEY = process.env.OPENSEA_API_KEY;
exports.ARB_SEPOLIA_PK1 = process.env.ARB_SEPOLIA_PK1;
exports.ARB_SEPOLIA_PK2 = process.env.ARB_SEPOLIA_PK2;
exports.ARB_MAINNET_PK = process.env.ARB_MAINNET_PK;
exports.ARB_SEPOLIA_RPC = process.env.ARB_SEPOLIA_RPC;
exports.ARB_MAINNET_RPC = process.env.ARB_MAINNET_RPC;
//   export const SIP15_ZONE_MAINNET_ADDRESS = checkMainnetAddress(mainnetDeployments, 0)
exports.SIP15_ZONE_SEPOLIA_ADDRESS = (0, helpers_1.checkSepoliaAddress)(sepoliaDeployments, 0);
exports.VAULT721_SEPOLIA_ADAPTER_ADDRESS = (0, helpers_1.checkSepoliaAddress)(sepoliaDeployments, 1);
//   export const VAULT721_MAINNET_ADAPTER_ADDRESS = checkMainnetAddress(mainnetDeployments, 1)
exports.VAULT721_SEPOLIA_ADDRESS = sepoliaContracts.Vault721_Address;
exports.VAULT721_MAINNET_ADDRESS = mainnetContracts.Vault721_Address;
exports.VAULT721_ANVIL_ADDRESS = process.env.VAULT721_ANVIL_ADDRESS;
//   export const ENCODING_HELPER_MAINNET = checkMainnetAddress(mainnetDeployments, 2)
exports.ENCODING_HELPER_SEPOLIA = (0, helpers_1.checkSepoliaAddress)(sepoliaDeployments, 2);
exports.Vault721AdapterABI = require("../../out/Vault721Adapter.sol/Vault721Adapter.json");
exports.EncodeSubstandard5ForEthersABI = require("../../out/EncodeSubstandard5ForEthers.sol/EncodeSubstandard5ForEthers.json");
exports.Vault721ABI = require("../../out/Vault721.sol/Vault721.json");
exports.ERC20ABI = require("../../out/ERC20.sol/ERC20.json");
class Web3Environment {
    constructor(walletType, chain) {
        if (chain == "sepolia") {
            if (walletType == 'offerer') {
                if (exports.ARB_SEPOLIA_RPC && exports.ARB_SEPOLIA_PK2) {
                    this.provider = new ethers_1.ethers.JsonRpcProvider(exports.ARB_SEPOLIA_RPC);
                    this.wallet = new ethers_1.ethers.Wallet(exports.ARB_SEPOLIA_PK2, this.provider);
                    this.seaport = new seaport_js_1.Seaport(this.wallet);
                }
                else {
                    throw new Error(".env VARS missing: ARB_SEPOLIA_RPC, ARB_SEPOLIA_PK");
                }
            }
            else {
                if (exports.ARB_SEPOLIA_RPC && exports.ARB_SEPOLIA_PK1) {
                    this.provider = new ethers_1.ethers.JsonRpcProvider(exports.ARB_SEPOLIA_RPC);
                    this.wallet = new ethers_1.ethers.Wallet(exports.ARB_SEPOLIA_PK1, this.provider);
                    this.seaport = new seaport_js_1.Seaport(this.wallet);
                }
                else {
                    throw new Error(".env VARS missing: ARB_SEPOLIA_RPC, ARB_SEPOLIA_PK");
                }
            }
            if (exports.VAULT721_SEPOLIA_ADAPTER_ADDRESS &&
                exports.SIP15_ZONE_SEPOLIA_ADDRESS &&
                exports.VAULT721_SEPOLIA_ADDRESS) {
                this.vault721AdapterAddress = exports.VAULT721_SEPOLIA_ADAPTER_ADDRESS;
                this.vault721Address = exports.VAULT721_SEPOLIA_ADDRESS;
                this.sip15ZoneAddress = exports.SIP15_ZONE_SEPOLIA_ADDRESS;
            }
            else {
                throw new Error("VAULT721_SEPOLIA_ADAPTER_ADDRESS undefined");
            }
            // if no helper exists deploy helper
            if (!exports.ENCODING_HELPER_SEPOLIA) {
                this.deployEncodingHelper();
            }
            else {
                this.encodeSubstandard5Helper = new ethers_1.ethers.Contract(exports.ENCODING_HELPER_SEPOLIA, exports.EncodeSubstandard5ForEthersABI.abi, this.wallet);
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
        }
        else {
            throw new Error("unsupported chain");
        }
        this.vault721Adapter = new ethers_1.ethers.Contract(this.vault721AdapterAddress, exports.Vault721AdapterABI.abi, this.wallet);
        this.vault721 = new ethers_1.ethers.Contract(this.vault721Address, exports.Vault721ABI.abi, this.wallet);
    }
    async deployEncodingHelper() {
        const encodeSubstandard5Factory = new ethers_1.ethers.ContractFactory(exports.EncodeSubstandard5ForEthersABI.abi, exports.EncodeSubstandard5ForEthersABI.bytecode, this.wallet);
        this.encodeSubstandard5Helper =
            (await encodeSubstandard5Factory.deploy());
    }
}
exports.Web3Environment = Web3Environment;
