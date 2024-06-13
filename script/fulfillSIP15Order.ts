import { Web3Environment, ERC20ABI } from "./utils/constants";
import { convertBigIntsToStrings, getExtraData } from "./utils/helpers";
import { OrderWithCounter } from "@opensea/seaport-js/src/types";
import {ethers} from 'ethers';
import fs from "fs";
import path from "path";

const args = process.argv.slice(2);
const chain = args[0];
const jsonPath = args[1];

const fulfillSIP15Order = async (chain: string, pathToOrder: string) => {
  const web3Env = new Web3Environment('fulfiller', chain);
  const seaport = web3Env.seaport;
  const wallet = web3Env.wallet;
  

  const _path = path.join(pathToOrder);
  const orderWithCounter = JSON.parse(
    fs.readFileSync(_path, "utf-8")
  ) as OrderWithCounter;
  
  const erc20 = new ethers.Contract(orderWithCounter.parameters.consideration[0].token, ERC20ABI.abi, wallet);
  const extraData = await getExtraData(
    web3Env,
    orderWithCounter.parameters.offer[0].identifierOrCriteria
  );

  try {
    const conduitAddress = (await seaport.contract.information()).conduitController;
    const seaportAddress = await seaport.contract.getAddress();
    console.log('seaport address:', seaportAddress);
    console.log('conduit adress:',conduitAddress);
    await erc20.approve(seaportAddress, ethers.MaxUint256);
    await erc20.approve(conduitAddress, ethers.MaxUint256);
    await erc20.approve(wallet.address, ethers.MaxUint256);
    console.log('balance of:', await erc20.balanceOf(wallet.address));

    const { executeAllActions } = await seaport.fulfillOrder({
      order: orderWithCounter,
      unitsToFill: 1,
      extraData: extraData,
      exactApproval: true
    });
    
    const fulfillment = await executeAllActions();

    console.log(
      "Successfully fulfilled a listing:", fulfillment.to
    );
  } catch (error) {
    console.error("Error in fulfillment:", error);
  }
};

// Check if the module is the main entry point
if (require.main === module) {
  // If yes, run the createOffer function
  fulfillSIP15Order(chain, jsonPath).catch(
    (error) => {
      console.error("Error in fulfillSIP15ZoneOrder:", error);
    }
  );
}

export default fulfillSIP15Order;
