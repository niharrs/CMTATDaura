//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

// required OZ imports here
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./modules/BaseModule.sol";
import "./modules/AuthorizationModule.sol";
import "./modules/BurnModule.sol";
import "./modules/MintModule.sol";
import "./modules/PauseModule.sol";
import "./modules/ValidationModule.sol";
import "./modules/MetaTxModule.sol";
import "./modules/SnapshotModule.sol";
import "./GlobalList.sol";
import "./RuleEngine.sol";
import "./interfaces/IRuleEngine.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CMTAT is
    Initializable,
    ContextUpgradeable,
    BaseModule,
    AuthorizationModule,
    PauseModule,
    MintModule,
    BurnModule,
    ValidationModule,
    MetaTxModule,
    SnapshotModule
{
    using EnumerableSet for EnumerableSet.AddressSet;

    enum REJECTED_CODE {
        TRANSFER_OK,
        TRANSFER_REJECTED_PAUSED
    }

    string constant TEXT_TRANSFER_OK = "No restriction";
    bytes32 public constant LIST_ROLE = keccak256("LIST_ROLE");

    uint256 public transferCount;
    bytes32 public termsHash;

    bool public isSecurityDLT;
    bool public useRuleEngine;

    /**
     * @dev Emitted when symbol property of ERC20 is changed
     */
    event Symbol(string symbol);

    event TermSet(string newTerm);
    event TokenIdSet(string newTokenId);
    /**
     * @dev Emitted when new hash of terms is set
     */
    event HashSet(bytes32 newHash);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) MetaTxModule(forwarder) {}

    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        string memory tokenId,
        string memory terms,
        bytes32 termsHash_,
        bool isSecurityDLT_,
        GlobalList globalList,
        address dauraWallet,
        bool useRuleEngine_,
        address[] memory guardianAddresses
    ) public initializer {
        __CMTAT_init(
            owner,
            name,
            symbol,
            tokenId,
            terms,
            termsHash_,
            isSecurityDLT_,
            globalList,
            dauraWallet,
            useRuleEngine_,
            guardianAddresses
        );
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __CMTAT_init(
        address owner,
        string memory name,
        string memory symbol,
        string memory tokenId,
        string memory terms,
        bytes32 termsHash_,
        bool isSecurityDLT_,
        GlobalList globalList,
        address dauraWallet,
        bool useRuleEngine_,
        address[] memory guardianAddresses
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Base_init_unchained(0, tokenId, terms);
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __Pausable_init_unchained();
        __Snapshot_init_unchained();
        __CMTAT_init_unchained(owner, dauraWallet);
        __Authorization_init_unchained(owner, guardianAddresses, globalList);

        termsHash = termsHash_;
        isSecurityDLT = isSecurityDLT_;

        if (useRuleEngine_) {
            RuleEngine _ruleEngine = new RuleEngine(
                globalList,
                IAccessControlUpgradeable(address(this))
            );
            ruleEngine = _ruleEngine;
            emit RuleEngineSet(address(_ruleEngine));
        }
        useRuleEngine = useRuleEngine_;
    }

    function __CMTAT_init_unchained(
        address owner,
        address dauraWallet
    ) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(BURNER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);
        _setupRole(SNAPSHOOTER_ROLE, owner);
        _setupRole(PAUSER_ROLE, dauraWallet);
        _setupRole(GUARDIAN_ROLE, owner);
        _setupRole(LIST_ROLE, owner);
        _setupRole(LIST_ROLE, dauraWallet);
    }

    /**
     *@dev set a new symbol. Reimport of token in Metamask needed to update GUI with new symbol.
     */
    function setSymbol(
        string memory symbol_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSymbol(symbol_);
        emit Symbol(symbol_);
    }

    /**
     * @dev set address to rule engine. If flag useRuleEngine set to false, the rule engine cannot bet used.
     * To deactivate rule engine set to address(0).
     */
    function setRuleEngine(
        IRuleEngine ruleEngine_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(useRuleEngine, "CMTAT: RuleEngine cannot be set");
        ruleEngine = ruleEngine_;
        emit RuleEngineSet(address(ruleEngine_));
    }

    /**
     * @dev ERC1404 returns the human readable explaination corresponding to the error code returned by detectTransferRestriction
     * @param restrictionCode The error code returned by detectTransferRestriction
     * @return message The human readable explaination corresponding to the error code returned by detectTransferRestriction
     */
    function messageForTransferRestriction(
        uint8 restrictionCode
    ) external view returns (string memory message) {
        if (restrictionCode == uint8(REJECTED_CODE.TRANSFER_OK)) {
            return TEXT_TRANSFER_OK;
        } else if (
            restrictionCode == uint8(REJECTED_CODE.TRANSFER_REJECTED_PAUSED)
        ) {
            return TEXT_TRANSFER_REJECTED_PAUSED;
        } else if (address(ruleEngine) != address(0)) {
            return _messageForTransferRestriction(restrictionCode);
        }
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /**
     * @dev Creates new tokens for a batch of addresses.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function batchMint(
        address[] calldata to,
        uint256[] calldata amounts
    ) public onlyRole(MINTER_ROLE) {
        uint256 len = to.length;
        require(
            len == amounts.length,
            "CMTAT: Length of 'accounts' not equal to length of 'amounts'"
        );
        for (uint256 i = 0; i < len; ) {
            _mint(to[i], amounts[i]);
            emit Mint(to[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`
     *
     * See {ERC20-_burn}
     *
     * Requirements:
     *
     * - the caller must have the BURNER_ROLE
     *
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public onlyRole(BURNER_ROLE) {
        _burn(account, amount);
        emit Burn(account, amount);
    }

    /**
     * @dev Destroys tokens from a batch of accounts
     *
     * See {ERC20-_burn}
     *
     * Requirements:
     *
     * - the caller must have the BURNER_ROLE
     *
     */
    function batchBurnFrom(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyRole(BURNER_ROLE) {
        uint256 len = accounts.length;
        require(
            len == amounts.length,
            "CMTAT: Length of 'accounts' not equal to length of 'amounts'"
        );
        for (uint256 i = 0; i < len; ) {
            _burn(accounts[i], amounts[i]);
            emit Burn(accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev burn and mint tokens in one tx
     * @param burnFrom_ address to burn tokens from
     * @param burnAmount_ amount of tokens to burn from "burnFrom_"
     * @param mintTo_ address to mint to
     * @param mintAmount_ amount of tokens to mint to "mintTo_"
     */
    function burnAndMint(
        address burnFrom_,
        uint256 burnAmount_,
        address mintTo_,
        uint256 mintAmount_
    ) public {
        burnFrom(burnFrom_, burnAmount_);
        mint(mintTo_, mintAmount_);
    }

    /**
     * @dev function for partial assignment of uncertificated securities. Will burn tokens from a wallet,
     *  mint back a specified amount, and mint tokens to a receiver wallet.
     * @param burnFrom_ address to burn tokens from
     * @param burnAmount_ amount of tokens to burn from "burnFrom_"
     * @param recoverAmount_ amount of tokens to recover from "burnFrom_"
     * @param mintTo_ address to mint to
     * @param mintAmount_ amount of tokens to mint to "mintTo"
     */
    function burnAndMintPartial(
        address burnFrom_,
        uint256 burnAmount_,
        uint256 recoverAmount_,
        address mintTo_,
        uint256 mintAmount_
    ) public {
        require(!isSecurityDLT, "CMTAT: Security must be uncertificated");
        require(
            recoverAmount_ <= burnAmount_,
            "CMTAT: Amount to recover is greater than amount to burn"
        );
        burnFrom(burnFrom_, burnAmount_);
        _checkRole(MINTER_ROLE);
        _mint(burnFrom_, recoverAmount_);
        emit Mint(burnFrom_, recoverAmount_);
        _mint(mintTo_, mintAmount_);
        emit Mint(mintTo_, mintAmount_);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev transfer 'amount' of tokens to 'recipient'. Requires security to be DLT
     * See {ERC20-transfer}.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        require(
            isSecurityDLT,
            "CMTAT: Security uncertificated. P2P transfer not allowed."
        );
        return super.transfer(recipient, amount);
    }

    /**
     * @dev transfer 'amount' of tokens to 'recipient' from 'sender'. Requires security to be DLT
     * See {ERC20-transferFrom}.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20Upgradeable, BaseModule) returns (bool) {
        require(
            isSecurityDLT,
            "CMTAT: Security uncertificated. P2P transfer not allowed."
        );
        return super.transferFrom(sender, recipient, amount);
    }

    function scheduleSnapshot(uint256 time) public onlyRole(SNAPSHOOTER_ROLE) {
        _scheduleSnapshot(time);
    }

    function rescheduleSnapshot(
        uint256 oldTime,
        uint256 newTime
    ) public onlyRole(SNAPSHOOTER_ROLE) {
        _rescheduleSnapshot(oldTime, newTime);
    }

    function unscheduleSnapshot(
        uint256 time
    ) public onlyRole(SNAPSHOOTER_ROLE) {
        _unscheduleSnapshot(time);
    }

    function setTokenId(
        string memory tokenId_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenId = tokenId_;
        emit TokenIdSet(tokenId_);
    }

    function setTerms(
        string memory terms_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        terms = terms_;
        emit TermSet(terms_);
    }

    function setHash(bytes32 termsHash_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        termsHash = termsHash_;
        emit HashSet(termsHash_);
    }

    /**
     * @dev set a new owner (or DEFAULT_ADMIN). Requires signature of two guardians. Will revoke all roles for old owner and grant all roles to new owner.
     */
    function setOwner(
        address newOwner,
        SignatureData calldata signatureData1,
        SignatureData calldata signatureData2
    ) public override onlyRole(GUARDIAN_ROLE) {
        require(
            signatureData1.signer != signatureData2.signer,
            "CMTAT: Signers are equal"
        );
        require(
            signatureData1.signer != _msgSender() &&
                signatureData2.signer != _msgSender(),
            "CMTAT: Signers can't be caller of function"
        );
        require(
            hasRole(GUARDIAN_ROLE, signatureData1.signer),
            "CMTAT: Signer1 doesn't have GUARDIAN_ROLE"
        );
        require(
            hasRole(GUARDIAN_ROLE, signatureData2.signer),
            "CMTAT: Signer2 doesn't have GUARDIAN_ROLE"
        );
        require(
            !usedSignatures[signatureData1.signature],
            "CMTAT: Signature of Signer1 already used"
        );
        require(
            !usedSignatures[signatureData2.signature],
            "CMTAT: Signature of Signer2 already used"
        );
        require(
            Signature.verify(
                signatureData1.signer,
                signatureData1.message,
                signatureData1.signature
            ),
            "CMTAT: Signature verification failed"
        );
        require(
            Signature.verify(
                signatureData2.signer,
                signatureData2.message,
                signatureData2.signature
            ),
            "CMTAT: Signature verification failed"
        );
        _revokeAllRoles(_owner);
        _grantAllRoles(newOwner);

        _owner = newOwner;

        usedSignatures[signatureData1.signature] = true;
        usedSignatures[signatureData2.signature] = true;
    }

    /// @custom:oz-upgrades-unsafe-allow selfdestruct
    /*     function kill() public onlyRole(DEFAULT_ADMIN_ROLE) {
        selfdestruct(payable(_msgSender()));
    } */

    /**
     * @dev ERC1404 check if _value token can be transferred from _from to _to
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     * @return code of the rejection reason
     */
    function detectTransferRestriction(
        address from,
        address to,
        uint256 amount
    ) public view returns (uint8 code) {
        if (paused()) {
            return uint8(REJECTED_CODE.TRANSFER_REJECTED_PAUSED);
        } else if (address(ruleEngine) != address(0)) {
            return _detectTransferRestriction(from, to, amount);
        }
        return uint8(REJECTED_CODE.TRANSFER_OK);
    }

    function decimals()
        public
        view
        virtual
        override(ERC20Upgradeable, BaseModule)
        returns (uint8)
    {
        return super.decimals();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(SnapshotModule, ERC20Upgradeable) {
        require(!paused(), "CMTAT: token transfer while paused");

        super._beforeTokenTransfer(from, to, amount);

        if (address(ruleEngine) != address(0)) {
            require(
                _validateTransfer(from, to, amount),
                "CMTAT: transfer rejected by validation module"
            );
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning. Will increase transferCount for every transfer, burn, mint.
     *
     * See {ERC20-_afterTokenTransfer}
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        transferCount++;
    }

    /**
     * @dev grant all roles to an account. Used only when setting new owner.
     */
    function _grantAllRoles(address account) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
        _grantRole(GUARDIAN_ROLE, account);
        _grantRole(MINTER_ROLE, account);
        _grantRole(BURNER_ROLE, account);
        _grantRole(PAUSER_ROLE, account);
        _grantRole(SNAPSHOOTER_ROLE, account);
        _grantRole(LIST_ROLE, account);
    }

    /**
     * @dev revoke all roles of an account
     */
    function _revokeAllRoles(address account) internal {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
        _revokeRole(GUARDIAN_ROLE, account);
        _revokeRole(MINTER_ROLE, account);
        _revokeRole(BURNER_ROLE, account);
        _revokeRole(PAUSER_ROLE, account);
        _revokeRole(SNAPSHOOTER_ROLE, account);
        _revokeRole(LIST_ROLE, account);
    }

    function _msgSender()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    uint256[50] private __gap;
}
