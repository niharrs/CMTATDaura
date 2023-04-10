//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract SignTypedData is EIP712 {
    using SignatureChecker for address;
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
    mapping(address => uint256) internal nonces;

    //    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() EIP712("daura", "1") {
        /*         DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("daura")),
                keccak256(bytes("1")),
                block.chainId,
                address(this)
            )
        ); */
    }

    // EIP712 message type data
    /*     struct ExampleMessage {
        string message;
        uint256 timestamp;
    }
 */
    // EIP712 message type hash
    /*     bytes32 private constant EXAMPLE_TYPEHASH =
        keccak256(
            abi.encodePacked("ExampleMessage(string message,uint256 timestamp)")
        ); */

    // Verify a signed message using EIP712 and ECDSA
    /*     function verifyExampleMessage(
        address signer,
        ExampleMessage memory message,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        EXAMPLE_TYPEHASH,
                        keccak256(bytes(message.message)),
                        message.timestamp
                    )
                )
            )
        );

        return signer == digest.recover(signature);
    } */

    function verify(
        address _signer,
        string memory _message,
        bytes memory signature
    ) public returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "SetOwner(address signer,string message,uint256 nonce)"
                    ),
                    _signer,
                    keccak256(bytes(_message)),
                    nonces[_signer]++
                )
            )
        );
        bool isValid = _signer.isValidSignatureNow(digest, signature);
        require(isValid, "Not a valid Signature");
        return isValid;
    }

    function toHash(string memory message) public pure returns (bytes32) {
        return keccak256(bytes(message));
    }
}
