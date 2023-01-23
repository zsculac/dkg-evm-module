import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  await hre.helpers.deploy({
    hre,
    newContractName: 'CommitManagerV1',
  });
};

export default func;
func.tags = ['CommitManagerV1'];
func.dependencies = [
  'Hub',
  'ScoringProxy',
  'ServiceAgreementV1',
  'Staking',
  'IdentityStorage',
  'ParametersStorage',
  'ProfileStorage',
  'ServiceAgreementStorageV1',
  'ShardingTableStorage',
  'StakingStorage',
];
