import { Wallet, Provider, Contract } from 'zksync-web3';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import * as dotenv from 'dotenv';
dotenv.config()

const walletPrivateKey = process.env.PRIVATE_KEY ?? "";

const factoryAddress = '0x5454605539E81ecfD30085Eba7ebBe80cB66eEA8';

const paymasterAddress = '0x231a2672996739351Bf25783b4883a1BAeAA5490';

const ownerAddress = '0x368493E7Ec4ffbFe236FA6A75165a346680BB8c7';
const contractName = 'DLTHU';
const contractSymbol = 'FFDSFSD';
const TOKEN_ID = 'Daura';
const contractTerms =
  'localhost:3000/smartContractFile/7061d214-1954-4aff-98dd-50ee884c5337';
const contractTermsHash =
  '0x6c6f63616c686f73743a333030302f736d617274436f6e747261637446696c65';
const isSecurityDLT = true;
const globalListAddress = '0xFf07e965181112F00B271A961f737B513a5E6b3A';
const dauraWalletAddress = '0x11307B101C800d40cb20bC09CEe25ea3897Ca6fc';
const useRuleEngine = true;
const guardianAddresses = [
  '0xc98fddaa24b8d1fb21d01c40134e40ab9dc963dc',
  '0x9f03D5226B48267123b8E4d264e619Fe2B243CE0',
];
const randomId = 8029;

// An example of a deploy script that will deploy and call a simple contract.
export default async function(hre: HardhatRuntimeEnvironment) {
  console.log(`Running factory to deploy new contract`);
  //const artifact = hre.artifacts.readArtifactSync('CMTATFactory');

  // Initialize the wallet.
  const provider = new Provider('https://zksync2-testnet.zksync.dev');
  const wallet = new Wallet(walletPrivateKey, provider);

  const deployer = new Deployer(hre, wallet);
//   const artifact = await deployer.loadArtifact('CMTAT');
//   const artifactRuleEngine = await deployer.loadArtifact('RuleEngine');
//   const artifactRule = await deployer.loadArtifact('Rule');

//   const cmtatContract = await deployer.deploy(
//     artifact,
//     [paymasterAddress],
//     {},
//     [artifactRuleEngine.bytecode, artifactRule.bytecode],
//   );

//   const CMTAT_ADDRESS = cmtatContract.address;
  
  const artifactCMTATFactory = await deployer.loadArtifact('CMTATFactory');
//   const cmtatFactory = await deployer.deploy(
//     artifactCMTATFactory,
//     [CMTAT_ADDRESS]
//   );

//   const contract = new Contract(cmtatFactory.address, artifactCMTATFactory.abi, wallet);
  const contract = new Contract(factoryAddress, artifactCMTATFactory.abi, wallet);
  console.log(contract.address);

  console.log('start building new contract');

//   await (
//     await contract.buildCMTAT(
//       OwnerAddress,
//       forwarderAddress,
//       constractName,
//       contractSymbol,
//       TOKEN_ID,
//       contractTerms,
//       contractTermsHash,
//       isSecurityDLT,
//       globalListAddress,
//       dauraWalletAddress,
//       useRuleEngine,
//       guardianAddresses,
//       randomId,
//     )
//   ).wait();

  try {
    const txReceipt = await contract.buildCMTAT(
      ownerAddress,
      paymasterAddress,
      contractName,
      contractSymbol,
      TOKEN_ID,
      contractTerms,
      contractTermsHash,
      isSecurityDLT,
      globalListAddress,
      dauraWalletAddress,
      useRuleEngine,
      guardianAddresses,
      randomId,
    )
    await txReceipt.wait(1);
  } catch(e) {
    console.log(e);
  }

  const newAddress = await contract.getAddress(randomId);

  console.log(`New CMTAT adddress ${newAddress}`);
}
