import * as dotenv from 'dotenv';

// Plugins
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-toolbox';
import '@nomiclabs/hardhat-etherscan';
import '@primitivefi/hardhat-dodoc';
import '@typechain/hardhat';
import 'hardhat-contract-sizer';
import 'hardhat-deploy';
import 'hardhat-tracer';
import { HardhatUserConfig } from 'hardhat/config';
import 'typechain';
import 'tapioca-sdk';

// Utils
import { HttpNetworkConfig } from 'hardhat/types';
import SDK from 'tapioca-sdk';

dotenv.config();
declare global {
    // eslint-disable-next-line @typescript-eslint/no-namespace
    namespace NodeJS {
        interface ProcessEnv {
            ALCHEMY_API_KEY: string;
        }
    }
}

type TNetwork = ReturnType<
    typeof SDK.API.utils.getSupportedChains
>[number]['name'];
const supportedChains = SDK.API.utils.getSupportedChains().reduce(
    (sdkChains, chain) => ({
        ...sdkChains,
        [chain.name]: <HttpNetworkConfig>{
            accounts:
                process.env.PRIVATE_KEY !== undefined
                    ? [process.env.PRIVATE_KEY]
                    : [],
            live: true,
            url: chain.rpc.replace('<api_key>', process.env.ALCHEMY_API_KEY),
            gasMultiplier: chain.tags[0] === 'testnet' ? 2 : 1,
            chainId: Number(chain.chainId),
            tags: [...chain.tags],
        },
    }),
    {} as { [key in TNetwork]: HttpNetworkConfig },
);

const config: HardhatUserConfig & { dodoc: any } = {
    solidity: {
        compilers: [
            {
                version: '0.4.24',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100,
                    },
                },
            },
            {
                version: '0.8.18',
                settings: {
                    viaIR: true,
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                    },
                },
            },
        ],
    },
    namedAccounts: {
        deployer: 0,
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
            accounts: {
                count: 5,
            },
        },
        ...supportedChains,
    },
    SDK: { project: 'tap-token' },
    etherscan: {
        apiKey: {
            goerli: process.env.BLOCKSCAN_KEY ?? '',
            arbitrumGoerli: process.env.ARBITRUM_GOERLI_KEY ?? '',
        },
        customChains: [],
    },
    mocha: {
        timeout: 4000000,
    },
    dodoc: {
        runOnCompile: false,
        freshOutput: true,
    },
    typechain: {
        outDir: 'typechain',
        target: 'ethers-v5',
    },
};

export default config;
