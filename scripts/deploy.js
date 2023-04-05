const { ethers } = require("hardhat");

// Deploy to Goerli: npx hardhat run scripts/deploy.js --network goerli

async function main() {

  const contractOwner = await ethers.getSigners();
  console.log(`Deploying contract from: ${contractOwner[0].address}`);
  const Giftokens = await ethers.getContractFactory('GiftokensV3');
  const giftokens = await Giftokens.deploy();
  await giftokens.deployed();
  console.log(`Giftokens deployed to: ${giftokens.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });