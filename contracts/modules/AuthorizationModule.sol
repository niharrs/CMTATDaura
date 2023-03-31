//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../GlobalList.sol";

library Signature {
    /**
     * @dev get keccak256 hash of the message
     */
    function getMessageHash(
        string memory _message
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /**
     * @dev Verify if signature was signed by _signer
     */
    function verify(
        address _signer,
        string memory _message,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

abstract contract AuthorizationModule is
    Initializable,
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    struct SignatureData {
        /**
         * @dev address of the signer
         */
        address signer;
        /**
         * @dev original message that was signed
         */
        string message;
        /**
         * @dev hash of the signed message
         */
        bytes signature;
    }

    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    address public _owner;
    GlobalList public globalList;
    /**
     * @dev iterable set of addresses of the guardians
     */
    EnumerableSet.AddressSet internal guardians;
    /**
     * @dev mapping of used signatures to prevent a signature from being used twice
     */
    mapping(bytes => bool) internal usedSignatures;

    function __Authorization_init(
        address owner_,
        address[] memory guardianAddresses,
        GlobalList globalList_
    ) internal onlyInitializing {
        __AccessControl_init();
        __Authorization_init_unchained(owner_, guardianAddresses, globalList_);
    }

    function __Authorization_init_unchained(
        address owner_,
        address[] memory guardianAddresses,
        GlobalList globalList_
    ) internal onlyInitializing {
        require(
            guardianAddresses.length < 6,
            "CMTAT: Not more than 5 guardians allowed"
        );
        for (uint i = 0; i < guardianAddresses.length; i++) {
            require(
                globalList_.isWhitelisted(guardianAddresses[i]),
                string(
                    abi.encodePacked(
                        "CMTAT: Address ",
                        guardianAddresses[i],
                        " is not on global whitelist"
                    )
                )
            );
            require(
                !globalList_.isBlacklisted(guardianAddresses[i]),
                string(
                    abi.encodePacked(
                        "CMTAT: Address ",
                        guardianAddresses[i],
                        " is in global freeze list"
                    )
                )
            );
            _setupRole(GUARDIAN_ROLE, guardianAddresses[i]);
        }
        globalList = globalList_;
        _owner = owner_;
    }

    /**
     * @dev Returns a list of all guardian addresses
     */
    function getGuardians() external view returns (address[] memory) {
        return guardians.values();
    }

    /**
     * @dev set a new owner (or DEFAULT_ADMIN). Requires signature of two guardians.
     */
    function setOwner(
        address newOwner,
        SignatureData calldata signatureData1,
        SignatureData calldata signatureData2
    ) public virtual onlyRole(GUARDIAN_ROLE) {}

    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(getRoleAdmin(role)) {
        require(
            role != DEFAULT_ADMIN_ROLE,
            "CMTAT: To set DEFAULT_ADMIN_ROLE use function setOwner"
        );
        if (role == GUARDIAN_ROLE) {
            isAddressValid(account);
        }
        _grantRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override onlyRole(getRoleAdmin(role)) {
        require(
            role != DEFAULT_ADMIN_ROLE,
            "CMTAT: Cannot revoke DEFAULT_ADMIN_ROLE. Need to set a new owner (see setOwner)."
        );
        _revokeRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal override {
        if (role == GUARDIAN_ROLE) {
            bool success = guardians.add(account);
            if (success) {
                super._grantRole(role, account);
            }
        } else {
            super._grantRole(role, account);
        }
    }

    function _revokeRole(bytes32 role, address account) internal override {
        if (role == GUARDIAN_ROLE) {
            bool success = guardians.remove(account);
            if (success) {
                super._revokeRole(role, account);
            }
        } else {
            super._revokeRole(role, account);
        }
    }

    function isAddressValid(address account) internal view {
        require(
            guardians.length() < 6,
            "CMTAT: Exceeds max number of guardians"
        );
        require(
            globalList.isWhitelisted(account),
            string(
                abi.encodePacked(
                    "CMTAT: Address ",
                    account,
                    " is not in global whitelist"
                )
            )
        );
        require(
            !globalList.isBlacklisted(account),
            string(
                abi.encodePacked(
                    "CMTAT: Address ",
                    account,
                    " is on global freeze list"
                )
            )
        );
    }
}
