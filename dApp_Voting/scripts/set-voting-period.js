const hre = require("hardhat");

const DEFAULT_START_TIME = "2026-05-01T00:00:00+07:00";
const DEFAULT_END_TIME = "2026-05-14T23:00:00+07:00";

function toUnixSeconds(value) {
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) {
    throw new Error(`Invalid date: ${value}`);
  }
  return Math.floor(ms / 1000);
}

async function main() {
  const contractAddress = process.env.CONTRACT_ADDRESS || process.argv[2];
  const startTimeInput = process.env.START_TIME || process.argv[3] || DEFAULT_START_TIME;
  const endTimeInput = process.env.END_TIME || process.argv[4] || DEFAULT_END_TIME;

  if (!contractAddress) {
    throw new Error(
      "Usage: CONTRACT_ADDRESS=0x... npx hardhat run scripts/set-voting-period.js --network sepolia"
    );
  }

  const startTime = toUnixSeconds(startTimeInput);
  const endTime = toUnixSeconds(endTimeInput);
  const voting = await hre.ethers.getContractAt("Voting", contractAddress);
  const owner = await voting.owner();
  const [signer] = await hre.ethers.getSigners();

  if (owner.toLowerCase() !== signer.address.toLowerCase()) {
    throw new Error(`Connected signer ${signer.address} is not contract owner ${owner}`);
  }

  const tx = await voting.setVotingPeriod(startTime, endTime);
  const receipt = await tx.wait(1);

  console.log("Voting period updated");
  console.log("Start:", startTimeInput, `(${startTime})`);
  console.log("End:", endTimeInput, `(${endTime})`);
  console.log("Transaction:", tx.hash);
  console.log("Block:", receipt.blockNumber);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
