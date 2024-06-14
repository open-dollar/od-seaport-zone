"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const ethers_1 = require("ethers");
const constants_1 = require("./utils/constants");
const constants_2 = require("@opensea/seaport-js/src/constants");
const helpers_1 = require("./utils/helpers");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const args = process.argv.slice(2);
const chain = args[0];
const vaultId = args[1].toString();
const listingAmount = args[2].toString();
const createSIP15ZoneListing = async (chain, vaultId, listingAmount) => {
    const web3Env = new constants_1.Web3Environment('offerer', chain);
    const vault721Address = web3Env.vault721Address;
    const vault721 = web3Env.vault721;
    const provider = web3Env.provider;
    const sip15ZoneAddress = web3Env.sip15ZoneAddress;
    const seaport = web3Env.seaport;
    const wallet = web3Env.wallet;
    /** @TODO  Fill in the token address and token ID of the NFT you want to sell, as well as the price */
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    let considerationTokenAddress = "0x8c12A21C8D62d794f78E02aE9e377Abee4750E87";
    listingAmount = ethers_1.ethers.parseEther(listingAmount).toString();
    console.log(vaultId, listingAmount);
    const extraData = await (0, helpers_1.getExtraData)(web3Env, vaultId.toString());
    // get zone hash by hashing extraData
    const zoneHash = ethers_1.ethers.keccak256(extraData);
    const timeStamp = (await provider.getBlock("latest")).timestamp;
    const timeDelay = await vault721.timeDelay();
    const createOrderInput = {
        offer: [
            {
                itemType: constants_2.ItemType.ERC721,
                token: vault721Address,
                identifier: vaultId,
            },
        ],
        consideration: [
            {
                token: considerationTokenAddress,
                amount: ethers_1.ethers.parseEther(listingAmount).toString(),
            },
        ],
        startTime: timeStamp,
        endTime: (ethers_1.ethers.toBigInt(timeStamp + 100) + timeDelay).toString(),
        zoneHash: zoneHash,
        zone: sip15ZoneAddress,
        restrictedByZone: true,
    };
    try {
        const conduit = (await seaport.contract.information()).conduitController;
        await vault721.setApprovalForAll(await seaport.contract.getAddress(), true);
        await vault721.setApprovalForAll(conduit, true);
        const { executeAllActions } = await seaport.createOrder(createOrderInput, wallet.address);
        const order = await executeAllActions();
        const parsedOrder = (0, helpers_1.convertBigIntsToStrings)(order);
        const outPath = path_1.default.join(`orders/order-${order.parameters.offer[0].identifierOrCriteria}-${order.parameters.startTime}.json`);
        fs_1.default.writeFile(outPath, JSON.stringify(parsedOrder, null, 2), (err) => {
            if (err) {
                console.error(err);
                return;
            }
            console.log("order written to file successfully!");
        });
        console.log("Successfully created a listing with orderHash:", order.parameters);
    }
    catch (error) {
        console.error("Error in createListing:", error);
    }
};
// Check if the module is the main entry point
if (require.main === module) {
    // If yes, run the createOffer function
    createSIP15ZoneListing(chain, vaultId, listingAmount).catch((error) => {
        console.error("Error in createListing:", error);
    });
}
exports.default = createSIP15ZoneListing;
