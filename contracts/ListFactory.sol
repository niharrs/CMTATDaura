// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./Beacon.sol";
import "./GlobalList.sol";

contract ListFactory {
    mapping(uint32 => address) private lists;
    Beacon immutable beacon;

    constructor(address _initBlueprint) {
        beacon = new Beacon(_initBlueprint);
    }

    function buildList(
        address[] memory whitelist,
        address[] memory blacklist,
        uint32 index
    ) public {
        BeaconProxy list = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                GlobalList(address(0)).initialize.selector,
                whitelist,
                blacklist
            )
        );
        lists[index] = address(list);
    }

    function getAddress(uint32 index) external view returns (address) {
        return lists[index];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }
}
