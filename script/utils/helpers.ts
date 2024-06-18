import { BigNumberish, BytesLike, ethers } from "ethers";
import { Web3Environment } from "./constants";
import { OrderWithCounter } from "@opensea/seaport-js/lib/types";

type ParsedObjectType = {
  [key: string]: string;
};

export type OrderWithExtraData = {
  order: OrderWithCounter;
  extraData: BytesLike;
};

export const convertOrder = (
  _order: OrderWithCounter,
  _extraData: BytesLike
): OrderWithExtraData => {
  return {
    order: _order,
    extraData: _extraData,
  };
};
export function stringToObject(str: string): ParsedObjectType {
  const parts = str.split(";");
  const trimmedObject: ParsedObjectType = {};
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

export function convertBigIntsToStrings(
  obj: Record<string, any>
): Record<string, any> {
  const newObj: Record<string, any> = {};

  for (const key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      const value = obj[key];
      if (typeof value === "bigint") {
        newObj[key] = value.toString();
      } else if (typeof value === "object" && !Array.isArray(value)) {
        newObj[key] = convertBigIntsToStrings(value);
      } else {
        newObj[key] = value;
      }
    }
  }

  return newObj;
}

export async function getExtraData(
  web3Env: Web3Environment,
  vaultId: string
): Promise<string> {
  // comparison Enums 3: equal to or less than... 5: equal to or greater than
  const _comparisonEnums: BigNumberish[] = [3, 5] as BigNumberish[];
  const _traitKeys: BytesLike[] = [
    ethers.keccak256(ethers.toUtf8Bytes("DEBT")),
    ethers.keccak256(ethers.toUtf8Bytes("COLLATERAL")),
  ];
  const _traitValues: BytesLike[] = await web3Env.vault721Adapter
    .getTraitValues(ethers.toBigInt(vaultId), _traitKeys)
    .then((array: BytesLike[]) =>
      array.map((e: BytesLike) => {
        return e;
      })
    );
  //create encoded substandard 5 data with helper contract
  const extraData = await web3Env.encodeSubstandard5Helper!.encodeSubstandard5(
    _comparisonEnums,
    web3Env.vault721Address,
    web3Env.vault721AdapterAddress,
    vaultId,
    _traitValues,
    _traitKeys
  );
  console.log(extraData);
  return extraData;
}
