import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { buildYieldBox } from '../builds/buildYieldBox';
import { buildERC20Mock } from '../builds/buildERC20Mock';
import { TChainIdDeployment } from 'tapioca-sdk/dist/shared';

export const loadVM = async (
    hre: HardhatRuntimeEnvironment,
    tag: string,
    debugMode = true,
) => {
    const VM = new hre.SDK.DeployerVM(hre, {
        // Change this if you get bytecode size error / gas required exceeds allowance (550000000)/ anything related to bytecode size
        // Could be different by network/RPC provider
        bytecodeSizeLimit: 80_000,
        debugMode,
        tag,
    });
    return VM;
};

export const deployYieldBox__task = async (
    {},
    hre: HardhatRuntimeEnvironment,
) => {
    console.log('[+] Deploying: YieldBox');
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const VM = await loadVM(hre, tag);
    const chainInfo = hre.SDK.utils.getChainBy('chainId', hre.SDK.eChainId);
    if (chainInfo === undefined) throw new Error('[-] Chain not supported');

    const isTestnet = chainInfo.tags.find((e) => e === 'testnet') !== undefined;

    // TODO Put WETH address in a config file
    // Revert if mainnet
    if (!isTestnet) {
        throw new Error('[-] WETH not found');
    }
    console.log('[-] WETH not found, deploying it on testnet');
    // Deploy it
    const depWeth = await (
        await (
            await hre.ethers.getContractFactory('ERC20Mock')
        ).deploy((1e18).toString())
    ).deployed();
    const weth = {
        name: 'WETHMock',
        address: depWeth.address,
        meta: {},
    };
    console.log(`[+] WETH deployed at ${weth.address}`);

    const [ybURI, yieldBox] = await buildYieldBox(hre, weth.address);
    VM.add(ybURI).add(yieldBox);

    await VM.execute(3);
    await VM.save();
    await VM.verify();
};
