import { Contract, Signer } from "ethers";
import { ethers } from "hardhat";

async function registerCommitmentOnchain(
  signer: Signer,
  requestId: number,
  commitment: number
) {
  const constractAbi =
    require("../artifacts/contracts/TensorRoyale.sol/TensorRoyale.json").abi;

  const contractAddress = "0xc28cF49aCCeFB1F570008Fe484d6D5AA22ac3f5C";
  const contract = new Contract(contractAddress, constractAbi, signer);

  let txRes = await contract.makeDeposit(
    ethers.ZeroAddress,
    requestId,
    commitment,
    0,
    { gasLimit: 3000000 }
  );

  let receipt = await txRes.wait();

  return receipt.transactionHash;
}

export default registerCommitmentOnchain;
