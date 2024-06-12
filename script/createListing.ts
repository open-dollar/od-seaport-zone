import { AddressLike, BigNumberish, BytesLike, ethers } from "ethers";
import {
  VAULT721_SEPOLIA_ADDRESS,
  VAULT721_ANVIL_ADDRESS,
  VAULT721_SEPOLIA_ADAPTER_ADDRESS,
  VAULT721_ANVIL_ADAPTER_ADDRESS,
  // VAULT721_MAINNET_ADAPTER_ADDRESS,
  VAULT721_MAINNET_ADDRESS,
  SIP15_ZONE_SEPOLIA_ADDRESS,
  ANVIL_ONE,
  ANVIL_RPC,
  ARB_SEPOLIA_RPC,
  ARB_MAINNET_RPC,
  ARB_SEPOLIA_PK,
  ARB_MAINNET_PK,
  ENCODING_HELPER_SEPOLIA,
  ENCODING_HELPER_ANVIL,
  // ENCODING_HELPER_MAINNET
} from "./utils/constants";
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from "@opensea/seaport-js/lib/types";
import { Seaport } from "@opensea/seaport-js";
import { Wallet, Provider } from "ethers";
import {
  Vault721Adapter,
  EncodeSubstandard5ForEthers,
} from "../types/ethers-contracts/index";

const vault721AdapterABI = require("../out/Vault721Adapter.sol/Vault721Adapter.json");
const EncodeSubstandard5ForEthersABI = require("../out/EncodeSubstandard5ForEthers.sol/EncodeSubstandard5ForEthers.json");

const createSIP15ZoneListing = async (chain: string) => {

  let provider: Provider;
  let wallet: Wallet;
  let seaport: Seaport;
  let encodeSubstandard5Helper: EncodeSubstandard5ForEthers;
  let vault721AdapterAddress: AddressLike;
  let vault721Address: AddressLike;
  let sip15ZoneAddress: AddressLike;



  if (chain == "anvil") {
    provider = new ethers.JsonRpcProvider(ANVIL_RPC);
    wallet = new ethers.Wallet(ANVIL_ONE as string, provider);
    seaport = new Seaport(wallet);

    if (VAULT721_ANVIL_ADAPTER_ADDRESS && VAULT721_ANVIL_ADDRESS) {
      vault721AdapterAddress = VAULT721_ANVIL_ADAPTER_ADDRESS;
      vault721Address = VAULT721_ANVIL_ADDRESS;
      sip15ZoneAddress = SIP15_ZONE_SEPOLIA_ADDRESS;
    } else {
      throw new Error("VAULT721_ANVIL_ADAPTER_ADDRESS undefined");
    }

    if (!ENCODING_HELPER_ANVIL) {
      const encodeSubstandard5Factory = new ethers.ContractFactory(
        EncodeSubstandard5ForEthersABI.abi,
        EncodeSubstandard5ForEthersABI.bytecode,
        wallet
      );

      encodeSubstandard5Helper =
        (await encodeSubstandard5Factory.deploy()) as EncodeSubstandard5ForEthers;

    } else {
      encodeSubstandard5Helper = new ethers.Contract(
        ENCODING_HELPER_ANVIL,
        EncodeSubstandard5ForEthersABI.abi,
        wallet
      ) as unknown as EncodeSubstandard5ForEthers;
    }
  } else if (chain == "sepolia") {
    provider = new ethers.JsonRpcProvider(ARB_SEPOLIA_RPC);
    wallet = new ethers.Wallet(ARB_SEPOLIA_PK as string, provider);
    seaport = new Seaport(wallet);

    if (VAULT721_SEPOLIA_ADAPTER_ADDRESS) {
      vault721AdapterAddress = VAULT721_SEPOLIA_ADAPTER_ADDRESS;
      vault721Address = VAULT721_SEPOLIA_ADDRESS;
      sip15ZoneAddress = SIP15_ZONE_SEPOLIA_ADDRESS;
    } else {
      throw new Error("VAULT721_SEPOLIA_ADAPTER_ADDRESS undefined");
    }

    // if no helper exists deploy helper
    if (!ENCODING_HELPER_SEPOLIA) {
      const encodeSubstandard5Factory = new ethers.ContractFactory(
        EncodeSubstandard5ForEthersABI.abi,
        EncodeSubstandard5ForEthersABI.bytecode,
        wallet
      );
      encodeSubstandard5Helper =
        (await encodeSubstandard5Factory.deploy()) as EncodeSubstandard5ForEthers;
    } else {
      encodeSubstandard5Helper = new ethers.Contract(
        ENCODING_HELPER_SEPOLIA,
        EncodeSubstandard5ForEthersABI.abi,
        wallet
      ) as unknown as EncodeSubstandard5ForEthers;
    }
  // } else if (chain == 'mainnet'){
  //   provider = new ethers.JsonRpcProvider(ARB_MAINNET_RPC);
  //   wallet = new ethers.Wallet(ARB_MAINNET_PK as string, provider);
  //   seaport = new Seaport(wallet);

  //   if (VAULT721_MAINNET_ADAPTER_ADDRESS && VAULT721_MAINNET_ADDRESS) {
  //     vault721AdapterAddress = VAULT721_MAINNET_ADAPTER_ADDRESS;
  //     vault721Address = VAULT721_MAINNET_ADDRESS;
  //   } else {
  //     throw new Error("VAULT721_MAINNET_ADAPTER_ADDRESS undefined");
  //   }

  //   // if no helper exists deploy helper
  //   if (!ENCODING_HELPER_MAINNET) {
  //     const encodeSubstandard5Factory = new ethers.ContractFactory(
  //       EncodeSubstandard5ForEthersABI.abi,
  //       EncodeSubstandard5ForEthersABI.bytecode,
  //       wallet
  //     );
  //     encodeSubstandard5Helper =
  //       (await encodeSubstandard5Factory.deploy()) as EncodeSubstandard5ForEthers;
  //   } else {
  //     encodeSubstandard5Helper = new ethers.Contract(
  //       ENCODING_HELPER_MAINNET,
  //       EncodeSubstandard5ForEthersABI.abi,
  //       wallet
  //     ) as unknown as EncodeSubstandard5ForEthers;
  //   }
  } else {
    throw new Error("unsupported chain");
  }
  // TODO: Fill in the token address and token ID of the NFT you want to sell, as well as the price
  let considerationTokenAddress: string = "0x8c12A21C8D62d794f78E02aE9e377Abee4750E87";
  let vaultId: string = "120";

  let listingAmount: string = ethers.parseEther("1").toString();

  const vault721Adapter = new ethers.Contract(
    vault721AdapterAddress,
    vault721AdapterABI.abi,
    wallet
  ) as unknown as Vault721Adapter;
 
  const _comparisonEnums: BigNumberish[] = [4, 5] as BigNumberish[];
  const _traitKeys: BytesLike[] = [
    ethers.keccak256(ethers.toUtf8Bytes("DEBT")),
    ethers.keccak256(ethers.toUtf8Bytes("COLLATERAL")),
  ];

  const _traitValues: BytesLike[] = await vault721Adapter.getTraitValues(
    ethers.toBigInt(vaultId),
    _traitKeys
  ).then((array) => array.map((e: BytesLike)=> {
    return e
  }));

  //create encoded substandard 5 data with helper
  const extraData = await encodeSubstandard5Helper.encodeSubstandard5(
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
    zone: SIP15_ZONE_SEPOLIA_ADDRESS,
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
