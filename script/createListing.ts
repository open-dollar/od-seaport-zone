import { ethers } from "ethers";
import {
  Web3Environment
} from "./utils/constants";
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";
import {convertBigIntsToStrings, getExtraData} from './utils/helpers';
import fs from "fs";
import path from "path";

const args = process.argv.slice(2);
const chain = args[0];
const vaultId = args[1].toString();
const listingAmount = args[2].toString();



const createSIP15ZoneListing = async (chain: string, vaultId: string, listingAmount:string) => {
  const web3Env = new Web3Environment(chain);
  const vault721Address = web3Env.vault721Address;
  const vault721 = web3Env.vault721;
  const provider = web3Env.provider;
  const sip15ZoneAddress = web3Env.sip15ZoneAddress;
  const seaport = web3Env.seaport;
  const wallet = web3Env.wallet;

  /** @TODO  Fill in the token address and token ID of the NFT you want to sell, as well as the price */
  ///////////////////////////////////////////////////////////////////////////////////////////////////////
  let considerationTokenAddress: string =
    "0x8c12A21C8D62d794f78E02aE9e377Abee4750E87";
  listingAmount = ethers.parseEther(listingAmount).toString();
  console.log(vaultId, listingAmount);
  const extraData = await getExtraData(web3Env, vaultId.toString());

  // get zone hash by hashing extraData
  const zoneHash = ethers.keccak256(extraData);
  const timeStamp = (await provider.getBlock("latest"))!.timestamp;
  const timeDelay = await vault721.timeDelay();

  const createOrderInput: CreateOrderInput = {
    offer: [
      {
        itemType: ItemType.ERC721,
        token: vault721Address,
        identifier: vaultId,
      },
    ],
    consideration: [
      {
        token: considerationTokenAddress,
        amount: ethers.parseEther(listingAmount!).toString(),
      },
    ],
    startTime: timeStamp,
    endTime: (ethers.toBigInt(timeStamp + 100) + timeDelay).toString(),
    zoneHash: zoneHash,
    zone: sip15ZoneAddress,
    restrictedByZone: true,
  };

  try {
    await vault721.approve(await seaport.contract.getAddress(), vaultId);
    const { executeAllActions } = await seaport.createOrder(
      createOrderInput,
      wallet.address
    );

    const order = await executeAllActions();

    const parsedOrder = convertBigIntsToStrings(order);

    const outPath = path.join(
      `orders/order-${order.parameters.offer[0].identifierOrCriteria}-${order.parameters.startTime}.json`
    );
     fs.writeFile(
      outPath, JSON.stringify(parsedOrder, null, 2),  (err) => {
        if (err) {
          console.error(err);
          return;
        }
    
        console.log("order written to file successfully!");
      });
    console.log(
      "Successfully created a listing with orderHash:",
      order.parameters
    );
  } catch (error) {
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

export default createSIP15ZoneListing;
