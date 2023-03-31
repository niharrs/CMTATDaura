//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract GlobalList is Initializable, OwnableUpgradeable {
    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;
    mapping(address => bool) private paymasterWhitelist;

    event AddToWhitelist(address indexed wallet);
    event AddToBlacklist(address indexed wallet);
    event RemoveFromBlacklist(address indexed wallet);
    event AddToPaymasterWhitelist(address indexed add);
    event RemoveFromPaymasterWhitelist(address indexed add);

    function initialize(
        address[] memory whitelist_,
        address[] memory blacklist_,
        address listOwner
    ) public initializer {
        __Ownable_init();
        _addToWhitelist(whitelist_);
        _setBlacklist(blacklist_, true);
        //to enable burning and minting, zero address has to be whitelisted
        whitelist[address(0)] = true;
        _transferOwnership(listOwner);
    }

    function addToPaymasterWhitelist(address add) external onlyOwner {
        require(
            paymasterWhitelist[add] == false,
            'GlobalList: Address already whitelisted in paymaster whitelist'
        );
        paymasterWhitelist[add] = true;
        emit AddToPaymasterWhitelist(add);
    }

    function batchAddToPaymasterWhitelist(
        address[] calldata adds
    ) external onlyOwner {
        _setPaymasterWhitelist(adds, true);
    }

    function removeFromPaymasterWhitelist(address add) external onlyOwner {
        require(
            paymasterWhitelist[add] == true,
            'GlobalList: Address not whitelisted in paymaster whitelist'
        );
        paymasterWhitelist[add] = false;
        emit RemoveFromPaymasterWhitelist(add);
    }

    function batchRemoveFromPaymasterWhitelist(
        address[] calldata adds
    ) external onlyOwner {
        _setPaymasterWhitelist(adds, false);
    }

    function addToWhitelist(address wallet_) external onlyOwner {
        require(
            whitelist[wallet_] == false,
            'GlobalList: Address already whitelisted'
        );
        whitelist[wallet_] = true;
        emit AddToWhitelist(wallet_);
    }

    function batchAddToWhitelist(address[] memory wallets_) external onlyOwner {
        _addToWhitelist(wallets_);
    }

    function addToBlacklist(address wallet_) external onlyOwner {
        require(
            blacklist[wallet_] == false,
            'GlobalList: Address already blacklisted'
        );
        blacklist[wallet_] = true;
        emit AddToWhitelist(wallet_);
    }

    function batchAddToBlacklist(address[] memory wallets_) external onlyOwner {
        _setBlacklist(wallets_, true);
    }

    function removeFromBlacklist(address wallet_) external onlyOwner {
        require(
            blacklist[wallet_] == true,
            'GlobalList: Address not blacklisted'
        );
        blacklist[wallet_] = false;
        emit RemoveFromBlacklist(wallet_);
    }

    function batchRemoveFromBlacklist(
        address[] calldata wallets_
    ) external onlyOwner {
        _setBlacklist(wallets_, false);
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function isBlacklisted(address addr) external view returns (bool) {
        return blacklist[addr];
    }

    function isWhitelistedPaymaster(address addr) external view returns (bool) {
        return paymasterWhitelist[addr];
    }

    function _addToWhitelist(address[] memory wallets_) internal {
        uint256 len = wallets_.length;
        for (uint256 i = 0; i < len; ) {
            address wallet_ = wallets_[i];
            if (!whitelist[wallet_]) {
                whitelist[wallet_] = true;
                emit AddToWhitelist(wallet_);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _setBlacklist(address[] memory wallets_, bool value) internal {
        uint256 len = wallets_.length;
        for (uint256 i = 0; i < len; ) {
            address wallet_ = wallets_[i];
            if (blacklist[wallet_] != value) {
                blacklist[wallet_] = value;
                if (value) {
                    emit AddToBlacklist(wallet_);
                } else {
                    emit RemoveFromBlacklist(wallet_);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function _setPaymasterWhitelist(
        address[] memory adds,
        bool value
    ) internal {
        uint256 len = adds.length;
        for (uint256 i = 0; i < len; ) {
            address add = adds[i];
            if (paymasterWhitelist[add] != value) {
                paymasterWhitelist[add] = value;
                if (value) {
                    emit AddToPaymasterWhitelist(add);
                } else {
                    emit RemoveFromPaymasterWhitelist(add);
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
