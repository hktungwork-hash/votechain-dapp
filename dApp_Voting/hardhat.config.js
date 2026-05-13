require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const sepoliaUrl = process.env.SEPOLIA_RPC_URL || process.env.SEPOLIA_URL;
const privateKey = process.env.SEPOLIA_PRIVATE_KEY || process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",

  networks: {
    sepolia: {
      url: sepoliaUrl,
      accounts: privateKey ? [privateKey] : [],
    },
  },
};
