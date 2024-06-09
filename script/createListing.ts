import { BytesLike, ethers } from 'ethers';
import {
    WALLET_ADDRESS,
    VAULT721_SEPOLIA_ADDRESS,
    VAULT721_SEPOLIA_ADAPATER_ADDRESS,
    SIP15_ZONE_SEPOLIA_ADDRESS,
    seaport,
    wallet
} from './utils/constants';
import { Vault721Adapter } from '../out/Vault721Adapter.sol/Vault721Adapter.json';
import { ItemType } from "@opensea/seaport-js/src/constants.ts";
const createSIP15ZoneListing = async () => {

    // TODO: Fill in the token address and token ID of the NFT you want to sell, as well as the price
    let considerationTokenAddress: string = "";
    let vaultId: string = "";
    let listingAmount: string = "";

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
    const _traitKeys: BytesLike[] = [ethers.keccak256('DEBT'), ethers.keccak256('COLLATERAL')];
    const _traitValues: BytesLike[] = await getValues(vaultId, _traitKeys);
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

    const listing = {
        offer: [
            {
                itemType: ItemType.ERC721,
                token: VAULT721_SEPOLIA_ADDRESS,
                identifier: vaultId
            },
        ],
        consideration: [
            {
                itemType: ItemType.ERC20,
                token: considerationTokenAddress,
                amount: ethers.parseEther(listingAmount).toString(),
                recipient: WALLET_ADDRESS
            },
        ],
        zoneHash: zoneHash,
        extraData: extraData
    }

    try {
        const { executeAllActions } = await seaport.createOrder(listing, wallet.address);
        const order = await executeAllActions();
        console.log("Successfully created a listing with orderHash:", order.parameters);
    } catch (error) {
        console.error("Error in createListing:", error);
    }
}

async function getValues(tokenId: string, _traitKeys: BytesLike[]): Promise<BytesLike[]> {
    const vault712Adapter = new
        // create adaptor contract
        //get values from adaptor
        //return values array
    return _traitKeys;
}

// Check if the module is the main entry point
if (require.main === module) {
    // If yes, run the createOffer function
    createSIP15ZoneListing().catch((error) => {
        console.error("Error in createListing:", error);
    });
}

export default createSIP15ZoneListing;