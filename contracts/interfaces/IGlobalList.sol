//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

interface IGlobalList {
    function addToPaymasterWhitelist(address add) external;

    function batchAddToPaymasterWhitelist(address[] calldata adds) external;

    function removeFromPaymasterWhitelist(address add) external;

    function batchRemoveFromPaymasterWhitelist(
        address[] calldata adds
    ) external;

    function addToWhitelist(address wallet_) external;

    function batchAddToWhitelist(address[] memory wallets_) external;

    function addToBlacklist(address wallet_) external;

    function batchAddToBlacklist(address[] memory wallets_) external;

    function removeFromBlacklist(address wallet_) external;

    function batchRemoveFromBlacklist(address[] calldata wallets_) external;

    function isWhitelisted(address addr) external view returns (bool);

    function isBlacklisted(address addr) external view returns (bool);

    function isWhitelistedPaymaster(address addr) external view returns (bool);
}
