const hre = require("hardhat");

async function main() {
  const contractAddress = process.env.CONTRACT_ADDRESS || process.argv[2];
  const voterAddress = process.env.VOTER_ADDRESS || process.argv[3];

  if (!contractAddress || !voterAddress) {
    throw new Error(
      "Usage: CONTRACT_ADDRESS=0x... VOTER_ADDRESS=0x... npx hardhat run scripts/reset-voter.js --network sepolia"
    );
  }

  const voting = await hre.ethers.getContractAt("Voting", contractAddress);
  const owner = await voting.owner();
  const [signer] = await hre.ethers.getSigners();

  if (owner.toLowerCase() !== signer.address.toLowerCase()) {
    throw new Error(`Connected signer ${signer.address} is not contract owner ${owner}`);
  }

  const tx = await voting.resetVoter(voterAddress);
  const receipt = await tx.wait(1);

  console.log("Voter reset:", voterAddress);
  console.log("Transaction:", tx.hash);
  console.log("Block:", receipt.blockNumber);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
