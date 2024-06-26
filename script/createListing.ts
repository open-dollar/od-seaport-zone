import { BytesLike, ethers } from "ethers";
import { Web3Environment } from "./utils/constants";
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";
import {
  convertBigIntsToStrings,
  getExtraData,
  convertOrder,
} from "./utils/helpers";
import fs from "fs";
import path from "path";

const args = process.argv.slice(2);
const chain = args[0];
const vaultId = args[1].toString();
const listingAmount = args[2].toString();

const createSIP15ZoneListing = async (
  chain: string,
  vaultId: string,
  listingAmount: string
) => {
  const web3Env = new Web3Environment("offerer", chain);
  const vault721Address = web3Env.vault721Address;
  const vault721 = web3Env.vault721;
  const provider = web3Env.provider;
  const sip15ZoneAddress = web3Env.sip15ZoneAddress;
  const seaport = web3Env.seaport;
  const wallet = web3Env.wallet;

  /** @TODO  Fill in the token address and token ID of the NFT you want to sell, as well as the price */
  ///////////////////////////////////////////////////////////////////////////////////////////////////////
  let considerationTokenAddress: string =
    "0x3018EC2AD556f28d2c0665d10b55ebfa469fD749";

  listingAmount = ethers.parseEther(listingAmount).toString();
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
        amount: listingAmount,
      },
    ],
    startTime: timeStamp,
    endTime: (ethers.toBigInt(timeStamp + 86400) + timeDelay).toString(),
    zoneHash: zoneHash,
    zone: sip15ZoneAddress,
    restrictedByZone: true,
  };

  try {
    const conduit = (await seaport.contract.information()).conduitController;
    await vault721.setApprovalForAll(await seaport.contract.getAddress(), true);
    await vault721.setApprovalForAll(conduit, true);
    const { executeAllActions } = await seaport.createOrder(
      createOrderInput,
      wallet.address
    );

    const order = await executeAllActions();

    const parsedOrder = convertBigIntsToStrings(convertOrder(order, extraData));

    const outPath = path.join(
      `orders/order-${order.parameters.offer[0].identifierOrCriteria}-${order.parameters.startTime}.json`
    );
    fs.writeFile(outPath, JSON.stringify(parsedOrder, null, 2), (err) => {
      if (err) {
        console.error(err);
        return;
      }

      console.log("order written to file successfully!");
    });
    console.log(
      "Successfully created a listing with orderHash:",
      seaport.getOrderHash(order.parameters)
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
