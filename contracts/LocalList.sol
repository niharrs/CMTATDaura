//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

// required OZ imports here
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract LocalList is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant LIST_ROLE = keccak256("LIST_ROLE");

    IAccessControlUpgradeable public immutable cmtat;

    EnumerableSet.AddressSet internal _localWhitelist;
    EnumerableSet.AddressSet internal _localBlacklist;

    /**
     * @dev Emitted when addresses are added to local whitelist
     */
    event AddToLocalWhitelist(address[] wallets);

    /**
     * @dev Emitted when addresses are added to local blacklist. wallets[i] == address(0) means an address that was supossed to be added was already on the whitelist.
     */
    event AddToLocalBlacklist(address[] wallets);

    /**
     * @dev Emitted when addresses are added/removed from local blacklist
     */
    event RemoveFromLocalBlacklist(address[] wallets);

    constructor(IAccessControlUpgradeable cmtat_) {
        cmtat = cmtat_;
    }

    function isWhitelistedLocally(address wallet) external view returns (bool) {
        return _localWhitelist.contains(wallet);
    }

    function isBlacklistedLocally(address wallet) external view returns (bool) {
        return _localBlacklist.contains(wallet);
    }

    function getLocalWhitelist() external view returns (address[] memory) {
        return _localWhitelist.values();
    }

    function getLocalBlacklist() external view returns (address[] memory) {
        return _localBlacklist.values();
    }

    /**
     *@dev Add wallets to local whitelist
     *@param wallets wallet addresses to add to whitelist
     */
    function addToLocalWhitelist(address[] memory wallets) external {
        require(
            cmtat.hasRole(LIST_ROLE, _msgSender()),
            "LocalList: Caller doesn't have List role"
        );
        uint256 walletsLength = wallets.length;
        for (uint i = 0; i < walletsLength; ) {
            address _wallet = wallets[i];
            bool added = _localWhitelist.add(_wallet);
            if (!added) {
                wallets[i] = address(0);
            }
            unchecked {
                ++i;
            }
        }
        emit AddToLocalWhitelist(wallets);
    }

    /**
     *@dev Add wallets to local blacklist
     *@param wallets wallets addresses to add to blacklist
     */
    function addToLocalBlacklist(address[] memory wallets) external {
        require(
            cmtat.hasRole(LIST_ROLE, _msgSender()),
            "LocalList: Caller doesn't have List role"
        );
        uint256 walletsLength = wallets.length;
        for (uint i = 0; i < walletsLength; ) {
            address _wallet = wallets[i];
            bool added = _localBlacklist.add(_wallet);
            if (!added) {
                wallets[i] = address(0);
            }
            unchecked {
                ++i;
            }
        }
        emit AddToLocalBlacklist(wallets);
    }

    /**
     *@dev Add wallets to local blacklist
     *@param wallets wallets addresses to add to blacklist/remove from blacklist
     */
    function removeFromLocalBlacklist(address[] memory wallets) external {
        require(
            cmtat.hasRole(LIST_ROLE, _msgSender()),
            "LocalList: Caller doesn't have List role"
        );
        uint256 walletsLength = wallets.length;
        for (uint i = 0; i < walletsLength; ) {
            address _wallet = wallets[i];
            bool removed = _localBlacklist.remove(_wallet);
            if (!removed) {
                wallets[i] = address(0);
            }
            unchecked {
                ++i;
            }
        }
        emit RemoveFromLocalBlacklist(wallets);
    }
}
