// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Guardian} from "../Guardian.sol";
import {Named} from "../interface/Named.sol";
import {Versioned} from "../interface/Versioned.sol";
import {ServiceAgreementStructsV1} from "../structs/ServiceAgreementStructsV1.sol";

contract ServiceAgreementStorageV1_1 is Named, Versioned, Guardian {
    string private constant _NAME = "ServiceAgreementStorageV1_1";
    string private constant _VERSION = "1.0.0";

    // AgreementId [hash(asset type contract + tokenId + key)] => ExtendedServiceAgreement
    mapping(bytes32 => ServiceAgreementStructsV1.ExtendedServiceAgreement) internal serviceAgreements;

    // CommitId [keccak256(agreementId + epoch + assertionId + identityId)] => stateCommitSubmission
    mapping(bytes32 => ServiceAgreementStructsV1.CommitSubmission) internal stateCommitSubmissions;

    // StateId [keccak256(agreementId + epoch + assertionId)] => stateCommitsCount
    mapping(bytes32 => uint8) internal stateCommitsCount;

    // StateId [keccak256(agreementId + epoch + assertionId)] => stateCommitDeadline
    mapping(bytes32 => uint256) internal stateCommitsDeadlines;

    constructor(address hubAddress) Guardian(hubAddress) {}

    modifier onlyContracts() {
        _checkHub();
        _;
    }

    function name() external pure virtual override returns (string memory) {
        return _NAME;
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
    }

    function createServiceAgreementObject(
        bytes32 agreementId,
        uint16 epochsNumber,
        uint128 epochLength,
        uint96 tokenAmount,
        uint8 scoreFunctionId,
        uint8 proofWindowOffsetPerc
    ) external onlyContracts {
        ServiceAgreementStructsV1.ExtendedServiceAgreement storage agreement = serviceAgreements[agreementId];
        agreement.startTime = block.timestamp;
        agreement.epochsNumber = epochsNumber;
        agreement.epochLength = epochLength;
        agreement.tokenAmount = tokenAmount;
        agreement.scoreFunctionId = scoreFunctionId;
        agreement.proofWindowOffsetPerc = proofWindowOffsetPerc;
    }

    function deleteServiceAgreementObject(bytes32 agreementId) external onlyContracts {
        delete serviceAgreements[agreementId];
    }

    function getAgreementData(
        bytes32 agreementId
    ) external view returns (uint256, uint16, uint128, uint96[2] memory, uint8[2] memory, bytes32) {
        return (
            serviceAgreements[agreementId].startTime,
            serviceAgreements[agreementId].epochsNumber,
            serviceAgreements[agreementId].epochLength,
            [serviceAgreements[agreementId].tokenAmount, serviceAgreements[agreementId].addedTokenAmount],
            [serviceAgreements[agreementId].scoreFunctionId, serviceAgreements[agreementId].proofWindowOffsetPerc],
            serviceAgreements[agreementId].latestFinalizedState
        );
    }

    function getAgreementStartTime(bytes32 agreementId) external view returns (uint256) {
        return serviceAgreements[agreementId].startTime;
    }

    function setAgreementStartTime(bytes32 agreementId, uint256 startTime) external onlyContracts {
        serviceAgreements[agreementId].startTime = startTime;
    }

    function getAgreementEpochsNumber(bytes32 agreementId) external view returns (uint16) {
        return serviceAgreements[agreementId].epochsNumber;
    }

    function setAgreementEpochsNumber(bytes32 agreementId, uint16 epochsNumber) external onlyContracts {
        serviceAgreements[agreementId].epochsNumber = epochsNumber;
    }

    function getAgreementEpochLength(bytes32 agreementId) external view returns (uint128) {
        return serviceAgreements[agreementId].epochLength;
    }

    function setAgreementEpochLength(bytes32 agreementId, uint128 epochLength) external onlyContracts {
        serviceAgreements[agreementId].epochLength = epochLength;
    }

    function getAgreementTokenAmount(bytes32 agreementId) external view returns (uint96) {
        return serviceAgreements[agreementId].tokenAmount;
    }

    function setAgreementTokenAmount(bytes32 agreementId, uint96 tokenAmount) external onlyContracts {
        serviceAgreements[agreementId].tokenAmount = tokenAmount;
    }

    function getAgreementAddedTokenAmount(bytes32 agreementId) external view returns (uint96) {
        return serviceAgreements[agreementId].addedTokenAmount;
    }

    function setAgreementAddedTokenAmount(bytes32 agreementId, uint96 addedTokenAmount) external onlyContracts {
        serviceAgreements[agreementId].addedTokenAmount = addedTokenAmount;
    }

    function getAgreementScoreFunctionId(bytes32 agreementId) external view returns (uint8) {
        return serviceAgreements[agreementId].scoreFunctionId;
    }

    function setAgreementScoreFunctionId(bytes32 agreementId, uint8 newScoreFunctionId) external onlyContracts {
        serviceAgreements[agreementId].scoreFunctionId = newScoreFunctionId;
    }

    function getAgreementProofWindowOffsetPerc(bytes32 agreementId) external view returns (uint8) {
        return serviceAgreements[agreementId].proofWindowOffsetPerc;
    }

    function setAgreementProofWindowOffsetPerc(
        bytes32 agreementId,
        uint8 proofWindowOffsetPerc
    ) external onlyContracts {
        serviceAgreements[agreementId].proofWindowOffsetPerc = proofWindowOffsetPerc;
    }

    function getAgreementLatestFinalizedState(bytes32 agreementId) external view returns (bytes32) {
        return serviceAgreements[agreementId].latestFinalizedState;
    }

    function setAgreementLatestFinalizedState(
        bytes32 agreementId,
        bytes32 latestFinalizedState
    ) external onlyContracts {
        serviceAgreements[agreementId].latestFinalizedState = latestFinalizedState;
    }

    function isStateFinalized(bytes32 agreementId, bytes32 state) external view returns (bool) {
        return state == this.getAgreementLatestFinalizedState(agreementId);
    }

    function getAgreementEpochSubmissionHead(
        bytes32 agreementId,
        uint16 epoch,
        bytes32 assertionId
    ) external view returns (bytes32) {
        return serviceAgreements[agreementId].epochSubmissionHeads[keccak256(abi.encodePacked(epoch, assertionId))];
    }

    function setAgreementEpochSubmissionHead(
        bytes32 agreementId,
        uint16 epoch,
        bytes32 assertionId,
        bytes32 headCommitId
    ) external onlyContracts {
        serviceAgreements[agreementId].epochSubmissionHeads[
            keccak256(abi.encodePacked(epoch, assertionId))
        ] = headCommitId;
    }

    function incrementAgreementRewardedNodesNumber(bytes32 agreementId, uint16 epoch) external onlyContracts {
        serviceAgreements[agreementId].rewardedNodesNumber[epoch]++;
    }

    function decrementAgreementRewardedNodesNumber(bytes32 agreementId, uint16 epoch) external onlyContracts {
        serviceAgreements[agreementId].rewardedNodesNumber[epoch]--;
    }

    function getAgreementRewardedNodesNumber(bytes32 agreementId, uint16 epoch) external view returns (uint32) {
        return serviceAgreements[agreementId].rewardedNodesNumber[epoch];
    }

    function setAgreementRewardedNodesNumber(
        bytes32 agreementId,
        uint16 epoch,
        uint32 rewardedNodesNumber
    ) external onlyContracts {
        serviceAgreements[agreementId].rewardedNodesNumber[epoch] = rewardedNodesNumber;
    }

    function serviceAgreementExists(bytes32 agreementId) external view returns (bool) {
        return serviceAgreements[agreementId].startTime != 0;
    }

    function createStateCommitSubmissionObject(
        bytes32 commitId,
        uint72 identityId,
        uint72 prevIdentityId,
        uint72 nextIdentityId,
        uint40 score
    ) external onlyContracts {
        stateCommitSubmissions[commitId] = ServiceAgreementStructsV1.CommitSubmission({
            identityId: identityId,
            prevIdentityId: prevIdentityId,
            nextIdentityId: nextIdentityId,
            score: score
        });
    }

    function deleteStateCommitSubmissionsObject(bytes32 commitId) external onlyContracts {
        delete stateCommitSubmissions[commitId];
    }

    function getStateCommitSubmission(
        bytes32 commitId
    ) external view returns (ServiceAgreementStructsV1.CommitSubmission memory) {
        return stateCommitSubmissions[commitId];
    }

    function getStateCommitSubmissionIdentityId(bytes32 commitId) external view returns (uint72) {
        return stateCommitSubmissions[commitId].identityId;
    }

    function setStateCommitSubmissionIdentityId(bytes32 commitId, uint72 identityId) external onlyContracts {
        stateCommitSubmissions[commitId].identityId = identityId;
    }

    function getStateCommitSubmissionPrevIdentityId(bytes32 commitId) external view returns (uint72) {
        return stateCommitSubmissions[commitId].prevIdentityId;
    }

    function setStateCommitSubmissionPrevIdentityId(bytes32 commitId, uint72 prevIdentityId) external onlyContracts {
        stateCommitSubmissions[commitId].prevIdentityId = prevIdentityId;
    }

    function getStateCommitSubmissionNextIdentityId(bytes32 commitId) external view returns (uint72) {
        return stateCommitSubmissions[commitId].nextIdentityId;
    }

    function setStateCommitSubmissionNextIdentityId(bytes32 commitId, uint72 nextIdentityId) external onlyContracts {
        stateCommitSubmissions[commitId].nextIdentityId = nextIdentityId;
    }

    function getStateCommitSubmissionScore(bytes32 commitId) external view returns (uint40) {
        return stateCommitSubmissions[commitId].score;
    }

    function setStateCommitSubmissionScore(bytes32 commitId, uint40 score) external onlyContracts {
        stateCommitSubmissions[commitId].score = score;
    }

    function stateCommitSubmissionExists(bytes32 commitId) external view returns (bool) {
        return stateCommitSubmissions[commitId].identityId != 0;
    }

    function incrementStateCommitsCount(bytes32 stateId) external onlyContracts {
        stateCommitsCount[stateId]++;
    }

    function decrementStateCommitsCount(bytes32 stateId) external onlyContracts {
        stateCommitsCount[stateId]--;
    }

    function getStateCommitsCount(bytes32 stateId) external view returns (uint8) {
        return stateCommitsCount[stateId];
    }

    function deleteStateCommitsCount(bytes32 stateId) external onlyContracts {
        delete stateCommitsCount[stateId];
    }

    function getStateCommitsDeadline(bytes32 stateId) external view returns (uint256) {
        return stateCommitsDeadlines[stateId];
    }

    function setStateCommitsDeadline(bytes32 stateId, uint256 deadline) external onlyContracts {
        stateCommitsDeadlines[stateId] = deadline;
    }

    function deleteStateCommitsDeadline(bytes32 stateId) external onlyContracts {
        delete stateCommitsDeadlines[stateId];
    }

    function transferAgreementTokens(address receiver, uint96 tokenAmount) external onlyContracts {
        tokenContract.transfer(receiver, tokenAmount);
    }

    function _checkHub() internal view virtual {
        require(hub.isContract(msg.sender), "Fn can only be called by the hub");
    }
}
