import { Web3Environment, ERC20ABI } from "./utils/constants";
import {
  getExtraData,
  OrderWithExtraData,
  convertOrder,
} from "./utils/helpers";
import { OrderWithCounter } from "@opensea/seaport-js/src/types";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";

const args = process.argv.slice(2);
const chain = args[0];
const jsonPath = args[1];

const fulfillSIP15Order = async (chain: string, pathToOrder: string) => {
  const web3Env = new Web3Environment("fulfiller", chain);
  const seaport = web3Env.seaport;
  const wallet = web3Env.wallet;

  const _path = path.join(pathToOrder);
  const orderWithExtraData: OrderWithExtraData = JSON.parse(
    fs.readFileSync(_path, "utf-8")
  ) as OrderWithExtraData;

  const erc20 = new ethers.Contract(
    orderWithExtraData.order.parameters.consideration[0].token,
    ERC20ABI.abi,
    wallet
  );
  const extraData = orderWithExtraData.extraData.toString();

  try {
    const conduitAddress = (await seaport.contract.information())
      .conduitController;
    const seaportAddress = await seaport.contract.getAddress();

    await erc20.approve(seaportAddress, ethers.MaxUint256);
    await erc20.approve(conduitAddress, ethers.MaxUint256);

    const { executeAllActions } = await seaport.fulfillOrder({
      order: orderWithExtraData.order,
      unitsToFill: 1,
      extraData: extraData,
      exactApproval: true,
    });

    const fulfillment = await executeAllActions();
    console.log("fulfillerAddress: ", wallet.address);
    console.log("Successfully fulfilled a listing:", fulfillment.to);
  } catch (error) {
    console.log("fulfillerAddress: ", wallet.address);
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

export default fulfillSIP15Order;
