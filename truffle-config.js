const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");
const BAOBAB_PRIVATE_KEY = "0x9bd8e94d3edc022a6d2b5d3e2fb6b55e1d300c72748dfb99db451cd885315373";

module.exports = {
    networks: {
        testnet: {
            provider: () => new HDWalletProvider(BAOBAB_PRIVATE_KEY, "https://public-node-api.klaytnapi.com/v1/baobab"),
            network_id: "1001",
            gas: "250000000",
            gasPrice: null,
            networkCheckTimeout: 1000000,
            timeoutBlocks: 200,
        },
    },

    compilers: {
        solc: {
            version: "0.8.0",
        },
    },
};
