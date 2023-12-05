import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const ParametersStorage = await hre.helpers.deploy({
    newContractName: 'ParametersStorage',
  });

  await hre.helpers.updateContractParameters('ParametersStorage', ParametersStorage);
};

export default func;
func.tags = ['ParametersStorage', 'v1'];
func.dependencies = ['Hub'];
