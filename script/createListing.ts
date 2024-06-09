import { BytesLike, keccak256, ethers } from 'ethers';
import { WALLET_ADDRESS, VAULT712_ADDRESS, VAULT712_ADAPATER_ADDRESS, sdk } from './utils/constants';

const createSIP15ZoneListing = async () => {

    // TODO: Fill in the token address and token ID of the NFT you want to sell, as well as the price
    let tokenAddress: string = "";
    let tokenId: string = "";
    let listingAmount: string = "";

    const listing = {
        accountAddress: WALLET_ADDRESS,
        startAmount: listingAmount,
        asset: {
            tokenAddress: tokenAddress,
            tokenId: tokenId,
        },
    };
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
    const _comparisonEnums: number[] = [4,5];
    const _traitKeys: BytesLike[] = [keccak256('DEBT'), keccak256('COLLATERAL')];
    const _traitValues: BytesLike[] = await getValues(tokenId, _traitKeys);
    const substandard5data = {
        comparisonEnums:_comparisonEnums,
        token: VAULT712_ADDRESS,
        traits: VAULT712_ADAPATER_ADDRESS,
        identifier: tokenId,
        traitValues: _traitValues,
        traitKeys: _traitKeys

    }

    try {
        const response = await sdk.createListing(listing);
        console.log("Successfully created a listing with orderHash:", response.orderHash);
    } catch (error) {
        console.error("Error in createListing:", error);
    }
}

async function getValues(tokenId: string, _traitKeys: BytesLike[]): Promise<BytesLike[]>{
        // import sip15 library
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