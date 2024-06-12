import { BigNumberish, BytesLike, ethers } from "ethers";
import {
  Web3ness
} from "./utils/constants";
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";



const createSIP15ZoneListing = async (chain: string) => {
  const web3ness = new Web3ness(chain);

  /** @TODO  Fill in the token address and token ID of the NFT you want to sell, as well as the price */
  //////////////////////////////////////////////////////////////////////////////////////////////////////

  let considerationTokenAddress: string =
    "0x8c12A21C8D62d794f78E02aE9e377Abee4750E87";
  let vaultId: string = "120";
  let listingAmount: string = ethers.parseEther("1").toString();



  const _comparisonEnums: BigNumberish[] = [4, 5] as BigNumberish[];
  const _traitKeys: BytesLike[] = [
    ethers.keccak256(ethers.toUtf8Bytes("DEBT")),
    ethers.keccak256(ethers.toUtf8Bytes("COLLATERAL")),
  ];

  const _traitValues: BytesLike[] = await web3ness.vault721Adapter
    .getTraitValues(ethers.toBigInt(vaultId), _traitKeys)
    .then((array) =>
      array.map((e: BytesLike) => {
        return e;
      })
    );

  //create encoded substandard 5 data with helper
  const extraData = await web3ness.encodeSubstandard5Helper!.encodeSubstandard5(
    _comparisonEnums,
    web3ness.vault721Address,
    web3ness.vault721AdapterAddress,
    vaultId,
    _traitValues,
    _traitKeys
  );

  // get zone hash by hashing extraData
  const zoneHash = ethers.keccak256(extraData);
  const timeStamp = (await web3ness.provider.getBlock("latest"))!.timestamp;

  const createOrderInput: CreateOrderInput = {
    offer: [
      {
        itemType: ItemType.ERC721,
        token: web3ness.vault721Address,
        identifier: vaultId,
      },
    ],
    consideration: [
      {
        token: considerationTokenAddress,
        amount: ethers.parseEther(listingAmount).toString(),
      },
    ],
    startTime: timeStamp,
    endTime: timeStamp,
    zoneHash: zoneHash,
    zone: web3ness.sip15ZoneAddress,
    restrictedByZone: true,
  };

  try {
    const { executeAllActions } = await web3ness.seaport.createOrder(
      createOrderInput,
      web3ness.wallet.address
    );
    const order = await executeAllActions();
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
  createSIP15ZoneListing("sepolia").catch((error) => {
    console.error("Error in createListing:", error);
  });
}

export default createSIP15ZoneListing;
