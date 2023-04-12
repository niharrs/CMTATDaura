// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./Beacon/Beacon.sol";
import "./CMTAT.sol";
import "./GlobalList.sol";

contract CMTATFactory {
    mapping(uint32 => address) private cmtats;
    Beacon immutable beacon;

    constructor(address _initBlueprint) {
        beacon = new Beacon(_initBlueprint);
    }

    function buildCMTAT(
        address _owner,
        address _forwarder,
        string memory _name,
        string memory _symbol,
        string memory _tokenId,
        string memory _terms,
        bytes32 _termsHash,
        bool isSecurityDLT_,
        GlobalList globalList,
        address dauraWallet,
        bool useRuleEngine,
        address[] memory guardianAddresses,
        uint32 _cmtatId
    ) public {
        BeaconProxy cmtat = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                CMTAT(address(new CMTAT(_forwarder))).initialize.selector,
                _owner,
                _name,
                _symbol,
                _tokenId,
                _terms,
                _termsHash,
                isSecurityDLT_,
                globalList,
                dauraWallet,
                useRuleEngine,
                guardianAddresses
            )
        );
        cmtats[_cmtatId] = address(cmtat);
    }

    function getAddress(uint32 _cmtatId) external view returns (address) {
        return cmtats[_cmtatId];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }
}
