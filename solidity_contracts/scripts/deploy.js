const { upgrades, ethers } = require("hardhat");

const path = require("path");
const dotenv = require("dotenv");
dotenv.config({ path: path.join(__dirname, "../.env") });

async function deployTensorRoyale() {
  const [deployer] = await ethers.getSigners();

  const tsRoyaleInstance = await ethers.deployContract("TensorRoyale", [], {
    signer: deployer,
  });
  let TensorRoyale = await tsRoyaleInstance.waitForDeployment();

  console.log(`Deployed TensorRoyale to ${await TensorRoyale.getAddress()}`);
}

deployTensorRoyale().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
