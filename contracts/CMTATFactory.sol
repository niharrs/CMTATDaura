// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./Beacon.sol";
import "./CMTAT.sol";

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
        uint32 _cmtatId
    ) public {
        BeaconProxy cmtat = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                CMTAT(address(0)).initialize.selector,
                _owner,
                _forwarder,
                _name,
                _symbol,
                _tokenId,
                _terms
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
