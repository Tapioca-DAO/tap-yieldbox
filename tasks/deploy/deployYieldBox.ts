import { HardhatRuntimeEnvironment } from 'hardhat/types';
import {
    TTapiocaDeployTaskArgs,
    TTapiocaDeployerVmPass,
} from 'tapioca-sdk/dist/ethers/hardhat/DeployerVM';
import { buildYieldBox } from '../builds/buildYieldBox';
import { DEPLOY_CONFIG } from './DEPLOY_CONFIG';

export const deployYieldBox__task = async (
    _taskArgs: TTapiocaDeployTaskArgs,
    hre: HardhatRuntimeEnvironment,
) => {
    await hre.SDK.DeployerVM.tapiocaDeployTask(
        _taskArgs,
        {
            hre,
            // Static simulation needs to be false, constructor relies on external call. We're using 0x00 replacement with DeployerVM, which creates a false positive for static simulation.
            staticSimulation: false,
        },
        tapiocaDeployTask,
    );
};

async function tapiocaDeployTask(params: TTapiocaDeployerVmPass<object>) {
    const { hre, VM } = params;

    const [ybURI, yieldBox] = await buildYieldBox(
        hre,
        DEPLOY_CONFIG.MISC[hre.SDK.eChainId]!.WETH!,
    );
    VM.add(ybURI).add(yieldBox);

    await VM.execute(3);
    await VM.save();
    await VM.verify();
}
