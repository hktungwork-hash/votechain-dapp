require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const sepoliaUrl = process.env.SEPOLIA_RPC_URL;
const privateKey = process.env.SEPOLIA_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",

  networks: sepoliaUrl && privateKey ? {
    sepolia: {
      url: sepoliaUrl,
      accounts: [privateKey],
    },
  } : {},
};
