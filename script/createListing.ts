import { BigNumberish, BytesLike, ethers } from "ethers";
import {
  Web3Environment
} from "./utils/constants";
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";



const createSIP15ZoneListing = async (chain: string) => {
  const web3Env = new Web3Environment(chain);
  const vault721Adapter = web3Env.vault721Adapter;
  const encodeSubstandard5Helper = web3Env.encodeSubstandard5Helper;
  const vault721AdapterAddress = web3Env.vault721AdapterAddress;
  const vault721Address = web3Env.vault721Address;
  const provider = web3Env.provider;
  const sip15ZoneAddress = web3Env.sip15ZoneAddress;
  const seaport = web3Env.seaport;
  const wallet = web3Env.wallet;

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

  const _traitValues: BytesLike[] = await vault721Adapter
    .getTraitValues(ethers.toBigInt(vaultId), _traitKeys)
    .then((array) =>
      array.map((e: BytesLike) => {
        return e;
      })
    );

  //create encoded substandard 5 data with helper
  const extraData = await encodeSubstandard5Helper!.encodeSubstandard5(
    _comparisonEnums,
    vault721Address,
    vault721AdapterAddress,
    vaultId,
    _traitValues,
    _traitKeys
  );

  // get zone hash by hashing extraData
  const zoneHash = ethers.keccak256(extraData);
  const timeStamp = (await provider.getBlock("latest"))!.timestamp;

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
        amount: ethers.parseEther(listingAmount).toString(),
      },
    ],
    startTime: timeStamp,
    endTime: timeStamp,
    zoneHash: zoneHash,
    zone: sip15ZoneAddress,
    restrictedByZone: true,
  };

  try {
    const { executeAllActions } = await seaport.createOrder(
      createOrderInput,
      wallet.address
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
