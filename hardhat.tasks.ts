import '@nomiclabs/hardhat-ethers';
import { task } from 'hardhat/config';
import { deployYieldBox__task } from './tasks/deploy/deployYieldBox';

task('deployYieldBox', 'Deploy YieldBox', deployYieldBox__task);
