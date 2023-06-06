import { ethers, run, network } from "hardhat";
const scannersMap: Record<number, string> = {
  11155111: "https://sepolia.etherscan.io/address/",
};

async function main() {
  // Library deployment
  const lib = await ethers.getContractFactory("tokenUtils");

  const libInstance = await lib.deploy();
  await libInstance.deployed();
  console.log("Library Address---> " + libInstance.address);
  const Lock = await ethers.getContractFactory("TimeLock", {
    libraries: { tokenUtils: libInstance.address },
  });
  const lock = await Lock.deploy();

  let contract = await lock.deployed();
  console.log(
    `contract deployed to: ${scannersMap[network.config.chainId!]}${
      contract.address
    }`
  );
  // await verify(libInstance.address);
  await verify(contract.address, libInstance.address);
  // console.log(network.config);
}

async function verify(
  contractAddress: string,
  libAddress: string,
  ...args: any
) {
  console.log(`verbifying contract --> ${contractAddress}`);
  try {
    await run("verify:verify", {
      libraries: {
        tokenUtils: libAddress,
      },
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(e);
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
