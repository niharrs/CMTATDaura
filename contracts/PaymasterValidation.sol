//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "./interfaces/IRule.sol";
import "./LocalList.sol";
import "./GlobalList.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymasterValidation is Ownable {
    GlobalList public globalList;
    address public factory;

    constructor(GlobalList globalList_, address factory_) {
        globalList = globalList_;
        factory = factory_;
    }

    function setGlobalList(GlobalList globalList_) external onlyOwner {
        globalList = globalList_;
    }

    function setFactory(address factory_) external onlyOwner {
        factory = factory_;
    }

    function validateAddress(address add) external view returns (bool) {
        if (
            !globalList.isWhitelistedPaymaster(add) &&
            !(add == factory) &&
            !(add == address(globalList))
        ) {
            return false;
        } else {
            return true;
        }
    }
}
