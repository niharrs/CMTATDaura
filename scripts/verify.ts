const hre = require("hardhat");

//npx hardhat verify --network zkTestnet 0x289CB7C043307227469a59a292c2648E5ee2859c --contract contracts/CMTAT.sol:CMTAT --constructor-args "0xEcC5e03785Af8D7c05Ef1A4A6E406f0dA6617FbB"
export enum ContractType {
    CMTAT = "contracts/CMTAT.sol:CMTAT",
    GlobalList = "contracts/GlobalList.sol:GlobalList",
    Factory = "contracts/CMTATFactory.sol:CMTATFactory",
}

export const verify = async (contractAddress: string, constructorArguments: string[], contractType: ContractType) => {
    await hre.run("verify:verify", {
        address: contractAddress,
        contract: contractType,
        constructorArguments: constructorArguments,
        noCompile: true
    });
}
