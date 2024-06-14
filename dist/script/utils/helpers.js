"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getExtraData = exports.convertBigIntsToStrings = exports.checkSepoliaAddress = exports.checkMainnetAddress = exports.stringToObject = void 0;
const ethers_1 = require("ethers");
function stringToObject(str) {
    const parts = str.split(";");
    const trimmedObject = {};
    parts
        .filter((element, i) => {
        return element.includes("=");
    })
        .forEach((e, i) => {
        const searchString = "address public";
        const thing = e.indexOf(searchString);
        const [key, value] = e
            .trim()
            .slice(thing + 12)
            .split("=");
        const trimmedKey = key.trim().replace(/^address\s+/, "");
        const trimmedValue = value.trim().replace(/;$/, "");
        trimmedObject[trimmedKey] = trimmedValue;
    });
    return trimmedObject;
}
exports.stringToObject = stringToObject;
function checkMainnetAddress(deployment, index) {
    return (() => {
        try {
            return deployment.receipts[index].contractAddress;
        }
        catch (error) {
            if (index == 0 && process.env.SIP15_ZONE_MAINNET_ADDRESS) {
                return process.env.SIP15_ZONE_MAINNET_ADDRESS;
            }
            else if (index == 1 && process.env.VAULT721_MAINNET_ADAPTER_ADDRESS) {
                return process.env.VAULT721_MAINNET_ADAPTER_ADDRESS;
            }
            else if (index == 2 && process.env.ENCODING_HELPER_MAINNET) {
                return process.env.ENCODING_HELPER_MAINNET;
            }
            else {
                console.error(error);
            }
        }
    })();
}
exports.checkMainnetAddress = checkMainnetAddress;
function checkSepoliaAddress(deployment, index) {
    return (() => {
        try {
            return deployment.receipts[index].contractAddress;
        }
        catch (error) {
            if (index == 0 && process.env.SIP15_ZONE_SEPOLIA_ADDRESS) {
                return process.env.SIP15_ZONE_SEPOLIA_ADDRESS;
            }
            else if (index == 1 && process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS) {
                return process.env.VAULT721_SEPOLIA_ADAPTER_ADDRESS;
            }
            else if (index == 2 && process.env.ENCODING_HELPER_SEPOLIA) {
                return process.env.ENCODING_HELPER_SEPOLIA;
            }
            else {
                console.error(error);
                throw new Error("addresses cannot be gotten");
            }
        }
    })();
}
exports.checkSepoliaAddress = checkSepoliaAddress;
function convertBigIntsToStrings(obj) {
    const newObj = {};
    for (const key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
            const value = obj[key];
            if (typeof value === 'bigint') {
                newObj[key] = value.toString();
            }
            else if (typeof value === 'object' && !Array.isArray(value)) {
                newObj[key] = convertBigIntsToStrings(value);
            }
            else {
                newObj[key] = value;
            }
        }
    }
    return newObj;
}
exports.convertBigIntsToStrings = convertBigIntsToStrings;
async function getExtraData(web3Env, vaultId) {
    const _comparisonEnums = [4, 5];
    const _traitKeys = [
        ethers_1.ethers.keccak256(ethers_1.ethers.toUtf8Bytes("DEBT")),
        ethers_1.ethers.keccak256(ethers_1.ethers.toUtf8Bytes("COLLATERAL")),
    ];
    const _traitValues = await web3Env.vault721Adapter
        .getTraitValues(ethers_1.ethers.toBigInt(vaultId), _traitKeys)
        .then((array) => array.map((e) => {
        return e;
    }));
    //create encoded substandard 5 data with helper contract
    const extraData = await web3Env.encodeSubstandard5Helper.encodeSubstandard5(_comparisonEnums, web3Env.vault721Address, web3Env.vault721AdapterAddress, vaultId, _traitValues, _traitKeys);
    return extraData;
}
exports.getExtraData = getExtraData;
