import { ethers } from "hardhat";

async function main() {
  const Greeter = await ethers.getContractFactory("Governance");
  const greeter = await Greeter.deploy("Vote for test", "Is solidity any good?");
  await greeter.deployed();

  console.log("Governance deployed to:", greeter.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
