import { Web3Environment, ERC20ABI } from "./utils/constants";
import { convertBigIntsToStrings, getExtraData } from "./utils/helpers";
import { OrderWithCounter } from "@opensea/seaport-js/src/types";
import {ethers} from 'ethers';
import fs from "fs";
import path from "path";


const fulfillSIP15Order = async (chain: string, pathToOrder: string) => {
  const web3Env = new Web3Environment(chain);
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
    const conduit = (await seaport.contract.information()).conduitController;
    console.log(await seaport.contract.getAddress());
    await erc20.approve(await seaport.contract.getAddress(), orderWithCounter.parameters.consideration[0].endAmount);
    await erc20.approve(conduit, orderWithCounter.parameters.consideration[0].endAmount);

    const { executeAllActions } = await seaport.fulfillOrder({
      order: orderWithCounter,
      extraData: extraData,
      exactApproval: true
    });
    
    const fulfillment = await executeAllActions();

    const parsedFulfillment = convertBigIntsToStrings(fulfillment);

    const outPath = path.join(
      `fullfillments/fullfillment-${parsedFulfillment.parameters.offer[0].identifierOrCriteria}-${parsedFulfillment.parameters.startTime}.json`
    );
    fs.writeFile(outPath, JSON.stringify(parsedFulfillment, null, 2), (err) => {
      if (err) {
        console.error(err);
        return;
      }

      console.log("order written to file successfully!");
    });
    console.log(
      "Successfully fulfilled a listing with orderHash:",
      parsedFulfillment.parameters
    );
  } catch (error) {
    console.error("Error in fulfillment:", error);
  }
};

// Check if the module is the main entry point
if (require.main === module) {
  // If yes, run the createOffer function
  fulfillSIP15Order("sepolia", "orders/order-120-1718295448.json").catch(
    (error) => {
      console.error("Error in fulfillSIP15ZoneOrder:", error);
    }
  );
}

export default fulfillSIP15Order;
