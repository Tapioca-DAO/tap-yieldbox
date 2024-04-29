import { EChainID } from '@tapioca-sdk/api/config';

// Name of the contract deployments to be used in the deployment scripts and saved in the deployments file
export const DEPLOYMENT_NAMES = {
    YieldBox: 'YieldBox',
    YieldBoxURIBuilder: 'YieldBoxURIBuilder',
};

type TMisc = {
    [key in EChainID]?: {
        WETH: string;
    };
};
const MISC: TMisc = {
    [EChainID.MAINNET]: {
        WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    },
    [EChainID.ARBITRUM]: {
        WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
    },
    [EChainID.ARBITRUM_SEPOLIA]: {
        WETH: '0x2EAe4fbc552fE35C1D3Df2B546032409bb0E431E',
    },
    [EChainID.SEPOLIA]: {
        WETH: '0xD8a79b479b0c47675E3882A1DAA494b6775CE227',
    },
    [EChainID.OPTIMISM_SEPOLIA]: {
        WETH: '0x4fB538Ed1a085200bD08F66083B72c0bfEb29112',
    },
};

export const DEPLOY_CONFIG = {
    MISC,
};
