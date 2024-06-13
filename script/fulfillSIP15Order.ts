import { Web3Environment } from "./utils/constants";
import { convertBigIntsToStrings, getExtraData } from "./utils/helpers";
import { OrderWithCounter } from "@opensea/seaport-js/src/types";
import fs from "fs";
import path from "path";

const fulfillSIP15Order = async (chain: string, pathToOrder: string) => {
  const web3Env = new Web3Environment(chain);
  const seaport = web3Env.seaport;

  const _path = path.join(pathToOrder);
  const orderWithCounter = JSON.parse(
    fs.readFileSync(_path, "utf-8")
  ) as OrderWithCounter;
  const extraData = await getExtraData(
    web3Env,
    orderWithCounter.parameters.offer[0].identifierOrCriteria
  );
  console.log(web3Env.wallet.address);
  try {
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
    console.error("Error in fullilment:", error);
  }
};

// Check if the module is the main entry point
if (require.main === module) {
  // If yes, run the createOffer function
  fulfillSIP15Order("sepolia", "orders/order-120-1718259233.json").catch(
    (error) => {
      console.error("Error in fulfillSIP15ZoneOrder:", error);
    }
  );
}

export default fulfillSIP15Order;
