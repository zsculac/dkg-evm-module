// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { HashingProxy } from "./HashingProxy.sol";
import { Hub } from "./Hub.sol";
import { Identity } from "./Identity.sol";
import { Shares } from "./Shares.sol";
import { Staking } from "./Staking.sol";
import { IdentityStorage } from "./storage/IdentityStorage.sol";
import { ProfileStorage } from "./storage/ProfileStorage.sol";
import { StakingStorage } from "./storage/StakingStorage.sol";
import { WhitelistStorage } from "./storage/WhitelistStorage.sol";
import { Named } from "./interface/Named.sol";
import { Versioned } from "./interface/Versioned.sol";
import { UnorderedIndexableContractDynamicSetLib } from "./utils/UnorderedIndexableContractDynamicSet.sol";
import { ADMIN_KEY, OPERATIONAL_KEY } from "./constants/IdentityConstants.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract Profile is Named, Versioned {

    event ProfileCreated(uint72 indexed identityId);
    event ProfileDeleted(uint72 indexed identityId);
    event AskUpdated(uint72 indexed identityId, uint96 ask);

    string constant private _NAME = "Profile";
    string constant private _VERSION = "1.0.0";

    Hub public hub;
    HashingProxy public hashingProxy;
    Identity public identityContract;
    Staking public stakingContract;
    IdentityStorage public identityStorage;
    ProfileStorage public profileStorage;
    StakingStorage public stakingStorage;
    WhitelistStorage public whitelistStorage;

    constructor(address hubAddress) {
        require(hubAddress != address(0));

        hub = Hub(hubAddress);
        initialize();
    }

    modifier onlyOwner() {
		_checkOwner();
		_;
	}

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

    function initialize() public onlyOwner {
		hashingProxy = HashingProxy(hub.getContractAddress("HashingProxy"));
        identityContract = Identity(hub.getContractAddress("Identity"));
        stakingContract = Staking(hub.getContractAddress("Staking"));
        identityStorage = IdentityStorage(hub.getContractAddress("IdentityStorage"));
        profileStorage = ProfileStorage(hub.getContractAddress("ProfileStorage"));
        stakingStorage = StakingStorage(hub.getContractAddress("StakingStorage"));
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
        bytes calldata nodeId,
        uint96 initialAsk,
        uint96 initialStake,
        uint8 operatorFee
    )
        external
        onlyWhitelisted
    {
        IdentityStorage ids = identityStorage;
        ProfileStorage ps = profileStorage;

        require(ids.getIdentityId(msg.sender) == 0, "Identity already exists");
        require(nodeId.length != 0, "Node ID can't be empty");
        require(!ps.nodeIdRegistered(nodeId), "Node ID is already registered");
        require(initialAsk != 0, "Ask cannot be 0");

        uint72 identityId = identityContract.createIdentity(msg.sender, adminWallet);

        string memory identityIdString = Strings.toString(identityId);
        Shares sharesContract = new Shares(
            address(hub),
            string.concat("Share token ", identityIdString),
            string.concat("DKGSTAKE_", identityIdString)
        );

        ps.createProfile(identityId, nodeId, initialAsk, address(sharesContract));
        _setAvailableNodeAddresses(identityId);

        Staking sc = stakingContract;
        sc.addStake(msg.sender, identityId, initialStake);
        sc.setOperatorFee(identityId, operatorFee);

        emit ProfileCreated(identityId);
    }

    function setAsk(uint72 identityId, uint96 ask) external onlyIdentityOwner(identityId) {
        require(ask != 0, "Ask cannot be 0");
        profileStorage.setAsk(identityId, ask);

        emit AskUpdated(identityId, ask);
    }

    // function deleteProfile(uint72 identityId) external onlyAdmin(identityId) {
    //     // TODO: add checks
    //     profileStorage.deleteProfile(identityId);
    //     identityContract.deleteIdentity(identityId);
    //
    //     emit ProfileDeleted(identityId);
    // }

    // function changeNodeId(uint72 identityId, bytes calldata nodeId) external onlyOperational(identityId) {
    //     require(nodeId.length != 0, "Node ID can't be empty");

    //     profileStorage.setNodeId(identityId, nodeId);
    // }

    // function addNewNodeIdHash(uint72 identityId, uint8 hashFunctionId) external onlyOperational(identityId) {
    //     require(hashingProxy.isHashFunction(hashFunctionId), "Hash function doesn't exist");

    //     profileStorage.setNodeAddress(identityId, hashFunctionId);
    // }

    // TODO: Define where it can be called, change internal modifier
    function _setAvailableNodeAddresses(uint72 identityId) internal {
        ProfileStorage ps = profileStorage;
        HashingProxy hp = hashingProxy;

        UnorderedIndexableContractDynamicSetLib.Contract[] memory hashFunctions = hp.getAllHashFunctions();
        uint256 hashFunctionsNumber = hashFunctions.length;
        for (uint8 i; i < hashFunctionsNumber; ) {
            ps.setNodeAddress(identityId, hashFunctions[i].id);
            unchecked { i++; }
        }
    }

    function stakeAccumulatedOperatorFee(uint72 identityId) external onlyAdmin(identityId) {
        ProfileStorage ps = profileStorage;

        uint96 accumulatedOperatorFee = ps.getAccumulatedOperatorFee(identityId);
        require(accumulatedOperatorFee != 0, "You have no operator fees");

        ps.setAccumulatedOperatorFee(identityId, 0);
        stakingContract.addStake(msg.sender, identityId, accumulatedOperatorFee);
    }

    function withdrawAccumulatedOperatorFee(uint72 identityId) external onlyAdmin(identityId) {
        ProfileStorage ps = profileStorage;

        uint96 accumulatedOperatorFee = ps.getAccumulatedOperatorFee(identityId);
        require(accumulatedOperatorFee != 0, "You have no operator fees");

        ps.setAccumulatedOperatorFee(identityId, 0);
        ps.transferTokens(msg.sender, accumulatedOperatorFee);
    }

    function _checkOwner() internal view virtual {
		require(msg.sender == hub.owner(), "Fn can only be used by hub owner");
	}

    function _checkIdentityOwner(uint72 identityId) internal view virtual {
        require(
            identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), ADMIN_KEY) ||
            identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), OPERATIONAL_KEY),
            "Fn can be used only by id owner"
        );
    }

    function _checkAdmin(uint72 identityId) internal view virtual {
        require(
            identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), ADMIN_KEY),
            "Admin function"
        );
    }

    function _checkOperational(uint72 identityId) internal view virtual {
        require(
            identityStorage.keyHasPurpose(identityId, keccak256(abi.encodePacked(msg.sender)), OPERATIONAL_KEY),
            "Fn can be called only by oper."
        );
    }

    function _checkWhitelist() internal view virtual {
        WhitelistStorage ws = whitelistStorage;
        if (ws.whitelistingEnabled()) {
            require(ws.whitelisted(msg.sender), "Address isn't whitelisted");
        }
    }

}
