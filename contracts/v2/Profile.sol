// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {HashingProxy} from "../v1/HashingProxy.sol";
import {Identity} from "../v1/Identity.sol";
import {Shares} from "../v1/Shares.sol";
import {IdentityStorage} from "./storage/IdentityStorage.sol";
import {ParametersStorage} from "../v1/storage/ParametersStorage.sol";
import {ProfileStorage} from "../v1/storage/ProfileStorage.sol";
import {StakingStorage} from "../v1/storage/StakingStorage.sol";
import {StakingV2} from "./Staking.sol";
import {WhitelistStorage} from "../v1/storage/WhitelistStorage.sol";
import {ContractStatus} from "../v1/abstract/ContractStatus.sol";
import {Initializable} from "../v1/interface/Initializable.sol";
import {Named} from "../v1/interface/Named.sol";
import {Versioned} from "../v1/interface/Versioned.sol";
import {UnorderedIndexableContractDynamicSetLib} from "../v1/utils/UnorderedIndexableContractDynamicSet.sol";
import {GeneralErrors} from "../v1/errors/GeneralErrors.sol";
import {ProfileErrors} from "./errors/ProfileErrors.sol";
import {StakingErrors} from "./errors/StakingErrors.sol";
import {ADMIN_KEY, OPERATIONAL_KEY} from "../v1/constants/IdentityConstants.sol";

contract ProfileV2 is Named, Versioned, ContractStatus, Initializable {
    event ProfileCreated(uint72 indexed identityId, bytes nodeId, address adminWallet, address sharesContractAddress);
    event ProfileDeleted(uint72 indexed identityId);
    event AskUpdated(uint72 indexed identityId, bytes nodeId, uint96 ask);

    string private constant _NAME = "Profile";
    string private constant _VERSION = "2.0.0";

    HashingProxy public hashingProxy;
    Identity public identityContract;
    StakingStorage public stakingStorage;
    StakingV2 public stakingContract;
    IdentityStorage public identityStorage;
    ParametersStorage public parametersStorage;
    ProfileStorage public profileStorage;
    WhitelistStorage public whitelistStorage;

    // solhint-disable-next-line no-empty-blocks
    constructor(address hubAddress) ContractStatus(hubAddress) {}

    modifier onlyIdentityOwner(uint72 identityId) {
        _checkIdentityOwner(identityId);
        _;
    }

    modifier onlyAdmin(uint72 identityId) {
        _checkAdmin(identityId);
        _;
    }

    modifier onlyOperational(uint72 identityId) {
        _checkOperational(identityId);
        _;
    }

    modifier onlyWhitelisted() {
        _checkWhitelist();
        _;
    }

    function initialize() public onlyHubOwner {
        hashingProxy = HashingProxy(hub.getContractAddress("HashingProxy"));
        identityContract = Identity(hub.getContractAddress("Identity"));
        stakingStorage = StakingStorage(hub.getContractAddress("StakingStorage"));
        stakingContract = StakingV2(hub.getContractAddress("Staking"));
        identityStorage = IdentityStorage(hub.getContractAddress("IdentityStorage"));
        parametersStorage = ParametersStorage(hub.getContractAddress("ParametersStorage"));
        profileStorage = ProfileStorage(hub.getContractAddress("ProfileStorage"));
        whitelistStorage = WhitelistStorage(hub.getContractAddress("WhitelistStorage"));
    }

    function name() external pure virtual override returns (string memory) {
        return _NAME;
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
    }

    function createProfile(
        address adminWallet,
        address[] calldata operationalWallets,
        bytes calldata nodeId,
        string calldata sharesTokenName,
        string calldata sharesTokenSymbol,
        uint8 initialOperatorFee
    ) external onlyWhitelisted {
        IdentityStorage ids = identityStorage;
        ProfileStorage ps = profileStorage;
        Identity id = identityContract;

        if (ids.getIdentityId(msg.sender) != 0)
            revert ProfileErrors.IdentityAlreadyExists(ids.getIdentityId(msg.sender), msg.sender);
        if (operationalWallets.length > parametersStorage.opWalletsLimitOnProfileCreation())
            revert ProfileErrors.TooManyOperationalWallets(
                parametersStorage.opWalletsLimitOnProfileCreation(),
                uint16(operationalWallets.length)
            );
        if (nodeId.length == 0) revert ProfileErrors.EmptyNodeId();
        if (ps.nodeIdsList(nodeId)) revert ProfileErrors.NodeIdAlreadyExists(nodeId);
        if (keccak256(abi.encodePacked(sharesTokenName)) == keccak256(abi.encodePacked("")))
            revert ProfileErrors.EmptySharesTokenName();
        if (keccak256(abi.encodePacked(sharesTokenSymbol)) == keccak256(abi.encodePacked("")))
            revert ProfileErrors.EmptySharesTokenSymbol();
        if (ps.sharesNames(sharesTokenName)) revert ProfileErrors.SharesTokenNameAlreadyExists(sharesTokenName);
        if (ps.sharesSymbols(sharesTokenSymbol)) revert ProfileErrors.SharesTokenSymbolAlreadyExists(sharesTokenSymbol);

        uint72 identityId = id.createIdentity(msg.sender, adminWallet);
        id.addOperationalWallets(identityId, operationalWallets);

        Shares sharesContract = new Shares(address(hub), sharesTokenName, sharesTokenSymbol);

        ps.createProfile(identityId, nodeId, address(sharesContract));
        _setAvailableNodeAddresses(identityId);

        stakingStorage.setOperatorFee(identityId, initialOperatorFee);

        emit ProfileCreated(identityId, nodeId, adminWallet, address(sharesContract));
    }

    function setAsk(uint72 identityId, uint96 ask) external onlyIdentityOwner(identityId) {
        if (ask == 0) revert ProfileErrors.ZeroAsk();

        ProfileStorage ps = profileStorage;
        ps.setAsk(identityId, ask);

        emit AskUpdated(identityId, ps.getNodeId(identityId), ask);
    }

    function _setAvailableNodeAddresses(uint72 identityId) internal virtual {
        ProfileStorage ps = profileStorage;
        HashingProxy hp = hashingProxy;

        bytes memory nodeId = ps.getNodeId(identityId);
        bytes32 nodeAddress;

        UnorderedIndexableContractDynamicSetLib.Contract[] memory hashFunctions = hp.getAllHashFunctions();
        require(hashFunctions.length <= parametersStorage.hashFunctionsLimit(), "Too many hash functions!");
        uint8 hashFunctionId;
        for (uint8 i; i < hashFunctions.length; ) {
            hashFunctionId = hashFunctions[i].id;
            nodeAddress = hp.callHashFunction(hashFunctionId, nodeId);
            ps.setNodeAddress(identityId, hashFunctionId, nodeAddress);
            unchecked {
                i++;
            }
        }
    }

    function stakeAccumulatedOperatorFee(uint72 identityId) external onlyAdmin(identityId) {
        ProfileStorage ps = profileStorage;

        uint96 accumulatedOperatorFee = ps.getAccumulatedOperatorFee(identityId);
        if (accumulatedOperatorFee == 0) revert ProfileErrors.NoOperatorFees(identityId);

        ps.setAccumulatedOperatorFee(identityId, 0);
        stakingContract.addStake(msg.sender, identityId, accumulatedOperatorFee);
    }

    function startAccumulatedOperatorFeeWithdrawal(uint72 identityId) external onlyAdmin(identityId) {
        ProfileStorage ps = profileStorage;

        uint96 accumulatedOperatorFee = ps.getAccumulatedOperatorFee(identityId);

        if (accumulatedOperatorFee == 0) revert ProfileErrors.NoOperatorFees(identityId);

        ps.setAccumulatedOperatorFee(identityId, 0);
        ps.setAccumulatedOperatorFeeWithdrawalAmount(
            identityId,
            ps.getAccumulatedOperatorFeeWithdrawalAmount(identityId) + accumulatedOperatorFee
        );
        ps.setAccumulatedOperatorFeeWithdrawalTimestamp(
            identityId,
            block.timestamp + parametersStorage.stakeWithdrawalDelay()
        );
    }

    function withdrawAccumulatedOperatorFee(uint72 identityId) external onlyAdmin(identityId) {
        ProfileStorage ps = profileStorage;

        uint96 withdrawalAmount = ps.getAccumulatedOperatorFeeWithdrawalAmount(identityId);

        if (withdrawalAmount == 0) revert StakingErrors.WithdrawalWasntInitiated();
        if (ps.getAccumulatedOperatorFeeWithdrawalTimestamp(identityId) >= block.timestamp)
            revert StakingErrors.WithdrawalPeriodPending(
                block.timestamp,
                ps.getAccumulatedOperatorFeeWithdrawalTimestamp(identityId)
            );

        ps.setAccumulatedOperatorFeeWithdrawalAmount(identityId, 0);
        ps.setAccumulatedOperatorFeeWithdrawalTimestamp(identityId, 0);
        ps.transferAccumulatedOperatorFee(msg.sender, withdrawalAmount);
    }

    function _checkIdentityOwner(uint72 identityId) internal view virtual {
        if (
            !identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), ADMIN_KEY) &&
            !identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), OPERATIONAL_KEY)
        ) revert GeneralErrors.OnlyProfileAdminOrOperationalAddressesFunction(msg.sender);
    }

    function _checkAdmin(uint72 identityId) internal view virtual {
        if (!identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), ADMIN_KEY))
            revert GeneralErrors.OnlyProfileAdminFunction(msg.sender);
    }

    function _checkOperational(uint72 identityId) internal view virtual {
        if (!identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), OPERATIONAL_KEY))
            revert GeneralErrors.OnlyProfileOperationalWalletFunction(msg.sender);
    }

    function _checkWhitelist() internal view virtual {
        WhitelistStorage ws = whitelistStorage;
        if (ws.whitelistingEnabled() && !ws.whitelisted(msg.sender))
            revert GeneralErrors.OnlyWhitelistedAddressesFunction(msg.sender);
    }
}
