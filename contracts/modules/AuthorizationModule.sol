//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/IGlobalList.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

abstract contract AuthorizationModule is
    Initializable,
    AccessControlUpgradeable,
    EIP712Upgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SignatureCheckerUpgradeable for address;
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
    IGlobalList public globalList;
    /**
     * @dev iterable set of addresses of the guardians
     */
    EnumerableSetUpgradeable.AddressSet internal guardians;
    /**
     * @dev to prevent a signature from being used twice
     */
    mapping(address => uint256) public nonces;

    function __Authorization_init(
        address owner_,
        address[] memory guardianAddresses,
        IGlobalList globalList_
    ) internal onlyInitializing {
        __AccessControl_init();
        __EIP712_init("daura", "1");
        __Authorization_init_unchained(owner_, guardianAddresses, globalList_);
    }

    function __Authorization_init_unchained(
        address owner_,
        address[] memory guardianAddresses,
        IGlobalList globalList_
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

    function verify(
        address _signer,
        string memory _message,
        bytes memory signature
    ) internal returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "SetOwner(address signer,string message,uint256 nonce)"
                    ),
                    _signer,
                    keccak256(bytes(_message)),
                    nonces[_signer]
                )
            )
        );
        bool isValid = _signer.isValidSignatureNow(digest, signature);
        if (isValid) {
            nonces[_signer]++;
        }
        return isValid;
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
