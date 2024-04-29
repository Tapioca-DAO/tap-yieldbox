import '@nomiclabs/hardhat-ethers';
import { scope } from 'hardhat/config';
import { TAP_TASK } from 'tapioca-sdk';
import { deployYieldBox__task } from './tasks/deploy/deployYieldBox';

const deployScope = scope('deploys', 'Deployment tasks');

TAP_TASK(deployScope.task('yieldBox', 'Deploy YieldBox', deployYieldBox__task));
