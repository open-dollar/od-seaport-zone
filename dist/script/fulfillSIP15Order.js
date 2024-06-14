"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const constants_1 = require("./utils/constants");
const helpers_1 = require("./utils/helpers");
const ethers_1 = require("ethers");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const args = process.argv.slice(2);
const chain = args[0];
const jsonPath = args[1];
const fulfillSIP15Order = async (chain, pathToOrder) => {
    const web3Env = new constants_1.Web3Environment('fulfiller', chain);
    const seaport = web3Env.seaport;
    const wallet = web3Env.wallet;
    const _path = path_1.default.join(pathToOrder);
    const orderWithCounter = JSON.parse(fs_1.default.readFileSync(_path, "utf-8"));
    const erc20 = new ethers_1.ethers.Contract(orderWithCounter.parameters.consideration[0].token, constants_1.ERC20ABI.abi, wallet);
    const extraData = await (0, helpers_1.getExtraData)(web3Env, orderWithCounter.parameters.offer[0].identifierOrCriteria);
    try {
        const conduitAddress = (await seaport.contract.information()).conduitController;
        const seaportAddress = await seaport.contract.getAddress();
        console.log('seaport address:', seaportAddress);
        console.log('conduit adress:', conduitAddress);
        await erc20.approve(seaportAddress, ethers_1.ethers.MaxUint256);
        await erc20.approve(conduitAddress, ethers_1.ethers.MaxUint256);
        await erc20.approve(wallet.address, ethers_1.ethers.MaxUint256);
        console.log('balance of:', await erc20.balanceOf(wallet.address));
        const { executeAllActions } = await seaport.fulfillOrder({
            order: orderWithCounter,
            unitsToFill: 1,
            extraData: extraData,
            exactApproval: true
        });
        const fulfillment = await executeAllActions();
        console.log("Successfully fulfilled a listing:", fulfillment.to);
    }
    catch (error) {
        console.error("Error in fulfillment:", error);
    }
};
// Check if the module is the main entry point
if (require.main === module) {
    // If yes, run the createOffer function
    fulfillSIP15Order(chain, jsonPath).catch((error) => {
        console.error("Error in fulfillSIP15ZoneOrder:", error);
    });
}
exports.default = fulfillSIP15Order;
