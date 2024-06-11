import { BytesLike, ethers } from 'ethers';
import {
    VAULT721_SEPOLIA_ADDRESS,
    VAULT721_SEPOLIA_ADAPATER_ADDRESS,
    SIP15_ZONE_SEPOLIA_ADDRESS,
    ANVIL_ONE,
    ANVIL_RPC,
    ARB_SEPOLIA_RPC,
    WALLET_PRIV_KEY
} from './utils/constants';
const vault721AdapterABI = require('../out/Vault721Adapter.sol/Vault721Adapter.json');
const sip15ZoneABI = require('../out/SIP15Zone.sol/SIP15Zone.json');
import { ItemType } from "@opensea/seaport-js/src/constants";
import { CreateOrderInput } from '@opensea/seaport-js/lib/types';
import { Seaport } from "@opensea/seaport-js";
import { Wallet, Provider } from 'ethers';
import {Vault721Adapter} from '../types/ethers-contracts/index';

const createSIP15ZoneListing = async (chain: string) => {
    let provider: Provider;
    let wallet: Wallet;
    let seaport: Seaport;
    if(chain == 'anvil'){
        provider = new ethers.JsonRpcProvider(ANVIL_RPC);
        wallet = new ethers.Wallet(
           ANVIL_ONE as string,
           provider
       );
        seaport = new Seaport(wallet);
    } else if (chain == 'sepolia'){
        provider = new ethers.JsonRpcProvider(ARB_SEPOLIA_RPC);
        wallet = new ethers.Wallet(
            WALLET_PRIV_KEY as string,
           provider
       );
        seaport = new Seaport(wallet);
    } else {
        throw new Error('unsupported chain');
    }

    // TODO: Fill in the token address and token ID of the NFT you want to sell, as well as the price
    let considerationTokenAddress: string = "";
    let vaultId: string = "1";
    let listingAmount: string = ethers.parseEther('1').toString();
    const vault721Adapter = new ethers.Contract(VAULT721_SEPOLIA_ADAPATER_ADDRESS!, vault721AdapterABI.abi, wallet) as unknown as Vault721Adapter;
    const sip15Zone = new ethers.Contract(SIP15_ZONE_SEPOLIA_ADDRESS!, sip15ZoneABI.abi);

    /**
     * struct Substandard5Comparison {
        uint8[] comparisonEnums;
        address token;
        address traits;
        uint256 identifier;
        bytes32[] traitValues;
        bytes32[] traitKeys;
    }
     */
    const substandard5ComparisonTypeString =
        'Substandard5Comparison(uint8[] comparisonEnums,address token,address traits,uint256 identifier,bytes32[] traitValues,bytes32[] traitKeys)'

    const _comparisonEnums: number[] = [4, 5];
    const _traitKeys: BytesLike[] = [ethers.keccak256(ethers.toUtf8Bytes('DEBT')), ethers.keccak256(ethers.toUtf8Bytes('COLLATERAL'))];
    const _traitValues: BytesLike[] = await vault721Adapter.getTraitValues(ethers.toBigInt(vaultId), _traitKeys);
    
    const substandard5data = {
        comparisonEnums: _comparisonEnums,
        token: VAULT721_SEPOLIA_ADDRESS,
        traits: VAULT721_SEPOLIA_ADAPATER_ADDRESS,
        identifier: vaultId,
        traitValues: _traitValues,
        traitKeys: _traitKeys
    }
    //encode data with struct fragment as type
    const encodedStruct = ethers.solidityPacked([substandard5ComparisonTypeString], [substandard5data]);
    //encode extraData with substandard
    const extraData = ethers.solidityPacked(['uint8', 'bytes'], [ethers.toBeHex('0x05'), encodedStruct]);
    // get zone hash by hashing extraData
    const zoneHash = ethers.keccak256(extraData);
    const timeStamp = (await provider.getBlock('latest'))!.timestamp;

    const createOrderInput: CreateOrderInput  = {
        offer: [
            {
                itemType: ItemType.ERC721,
                token: VAULT721_SEPOLIA_ADDRESS!,
                identifier: vaultId
            },
        ],
        consideration: [
            {
                token: considerationTokenAddress,
                amount: ethers.parseEther(listingAmount).toString()
            },
        ],
        startTime: timeStamp,
        endTime: 10,
        zoneHash: zoneHash,
        zone: SIP15_ZONE_SEPOLIA_ADDRESS,
        restrictedByZone: true,
    }

    try {
        const { executeAllActions } = await seaport.createOrder(createOrderInput, wallet.address);
        const order = await executeAllActions();
        console.log("Successfully created a listing with orderHash:", order.parameters);
    } catch (error) {
        console.error("Error in createListing:", error);
    }
}

// Check if the module is the main entry point
if (require.main === module) {
    // If yes, run the createOffer function
    createSIP15ZoneListing('anvil').catch((error) => {
        console.error("Error in createListing:", error);
    });
}

export default createSIP15ZoneListing;