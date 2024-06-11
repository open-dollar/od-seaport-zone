/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type { Signer, ContractDeployTransaction, ContractRunner } from "ethers";
import type { NonPayableOverrides } from "../common";
import type {
  EncodeSubstandard5ForEthers,
  EncodeSubstandard5ForEthersInterface,
} from "../EncodeSubstandard5ForEthers";

const _abi = [
  {
    type: "constructor",
    inputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "encodeSubstandard5",
    inputs: [
      {
        name: "comparisonEnums",
        type: "uint8[]",
        internalType: "uint8[]",
      },
      {
        name: "token",
        type: "address",
        internalType: "address",
      },
      {
        name: "traits",
        type: "address",
        internalType: "address",
      },
      {
        name: "identifier",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "traitValues",
        type: "bytes32[]",
        internalType: "bytes32[]",
      },
      {
        name: "traitKeys",
        type: "bytes32[]",
        internalType: "bytes32[]",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    stateMutability: "pure",
  },
] as const;

const _bytecode =
  "0x608060405234801561000f575f80fd5b506104ac8061001d5f395ff3fe608060405234801561000f575f80fd5b5060043610610029575f3560e01c8063d0a871751461002d575b5f80fd5b61004061003b3660046101e7565b610056565b60405161004d9190610318565b60405180910390f35b60605f6040518060c00160405280898152602001886001600160a01b03168152602001876001600160a01b031681526020018681526020018581526020018481525090506100a3816100af565b98975050505050505050565b60606005826040516020016100c49190610384565b60408051601f19818403018152908290526100e29291602001610448565b6040516020818303038152906040529050919050565b634e487b7160e01b5f52604160045260245ffd5b604051601f8201601f1916810167ffffffffffffffff81118282101715610135576101356100f8565b604052919050565b5f67ffffffffffffffff821115610156576101566100f8565b5060051b60200190565b80356001600160a01b0381168114610176575f80fd5b919050565b5f82601f83011261018a575f80fd5b8135602061019f61019a8361013d565b61010c565b8083825260208201915060208460051b8701019350868411156101c0575f80fd5b602086015b848110156101dc57803583529183019183016101c5565b509695505050505050565b5f805f805f8060c087890312156101fc575f80fd5b863567ffffffffffffffff80821115610213575f80fd5b818901915089601f830112610226575f80fd5b8135602061023661019a8361013d565b82815260059290921b8401810191818101908d841115610254575f80fd5b948201945b8386101561028057853560ff81168114610271575f80fd5b82529482019490820190610259565b9a5061028f90508b8201610160565b9850505061029f60408a01610160565b95506060890135945060808901359150808211156102bb575f80fd5b6102c78a838b0161017b565b935060a08901359150808211156102dc575f80fd5b506102e989828a0161017b565b9150509295509295509295565b5f5b838110156103105781810151838201526020016102f8565b50505f910152565b602081525f82518060208401526103368160408501602087016102f6565b601f01601f19169190910160400192915050565b5f815180845260208085019450602084015f5b838110156103795781518752958201959082019060010161035d565b509495945050505050565b6020808252825160c083830152805160e084018190525f929182019083906101008601905b808310156103cc57835160ff1682529284019260019290920191908401906103a9565b50928601516001600160a01b03811660408701529260408701516001600160a01b038116606088015293506060870151608087015260808701519350601f199250828682030160a0870152610421818561034a565b9350505060a0850151818584030160c086015261043e838261034a565b9695505050505050565b60ff60f81b8360f81b1681525f82516104688160018501602087016102f6565b91909101600101939250505056fea264697066735822122023956235668f9ec4be55d2e194eb1372e50490597c19ad9f319d2e0f29e0157064736f6c63430008180033";

type EncodeSubstandard5ForEthersConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: EncodeSubstandard5ForEthersConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class EncodeSubstandard5ForEthers__factory extends ContractFactory {
  constructor(...args: EncodeSubstandard5ForEthersConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(overrides || {});
  }
  override deploy(overrides?: NonPayableOverrides & { from?: string }) {
    return super.deploy(overrides || {}) as Promise<
      EncodeSubstandard5ForEthers & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(
    runner: ContractRunner | null
  ): EncodeSubstandard5ForEthers__factory {
    return super.connect(runner) as EncodeSubstandard5ForEthers__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): EncodeSubstandard5ForEthersInterface {
    return new Interface(_abi) as EncodeSubstandard5ForEthersInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): EncodeSubstandard5ForEthers {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as EncodeSubstandard5ForEthers;
  }
}