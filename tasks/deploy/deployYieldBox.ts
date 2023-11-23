import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { IDeployerVMAdd } from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { MockSwapper__factory } from '../../gitsub_tapioca-sdk/src/typechain/tapioca-mocks';
import MockSwapperArtifact from '../../gitsub_tapioca-sdk/src/artifacts/tapioca-mocks/MockSwapper.json';
import { EChainID } from '../../gitsub_tapioca-sdk/src/api/config';
import { buildYieldBox } from '../builds/buildYieldBox';

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
    console.log('[+] Deploying: MockSwapper');
    const tag = await hre.SDK.hardhatUtils.askForTag(hre, 'local');
    const VM = await loadVM(hre, tag);

    const chainInfo = hre.SDK.utils.getChainBy(
        'chainId',
        await hre.getChainId(),
    );
    if (!chainInfo) {
        throw new Error('Chain not found');
    }

    let weth = hre.SDK.db
        .loadGlobalDeployment(
            tag,
            hre.SDK.config.TAPIOCA_PROJECTS_NAME.TapiocaMocks,
            chainInfo.chainId,
        )
        .find((e) => e.name.startsWith('WETHMock'));

    if (!weth) {
        //try to take it again from local deployment
        weth = hre.SDK.db
            .loadLocalDeployment(tag, chainInfo.chainId)
            .find((e) => e.name.startsWith('WETHMock'));
    }
    if (weth) {
        const [ybURI, yieldBox] = await buildYieldBox(hre, weth.address);
        VM.add(ybURI).add(yieldBox);
    }

    await VM.execute(3);
    VM.save();
    await VM.verify();
};
