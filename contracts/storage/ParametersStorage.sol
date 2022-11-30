// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ParametersStorage is Ownable {

    uint96 public minimumStake;
    uint96 public maximumStake;

    uint48 public R2;
    uint32 public R1;
    uint32 public R0;

    uint16 public commitWindowDuration;
    uint8 public minProofWindowOffsetPerc;
    uint8 public maxProofWindowOffsetPerc;
    uint8 public proofWindowDurationPerc;
    uint8 public replacementWindowDurationPerc;

    uint128 public epochLength;

    uint24 public stakeWithdrawalDelay;
    uint24 public rewardWithdrawalDelay;
    uint32 public slashingFreezeDuration;

    bool public delegationEnabled;

    constructor() {
        minimumStake = 50_000 ether;
        maximumStake = 5_000_000 ether;

        R2 = 20;
        R1 = 8;
        R0 = 3;

        commitWindowDuration = 15 minutes;
        minProofWindowOffsetPerc = 50;
        maxProofWindowOffsetPerc = 75;
        proofWindowDurationPerc = 25;
        replacementWindowDurationPerc = 0;

        epochLength = 1 hours;

        stakeWithdrawalDelay = 5 minutes;
        rewardWithdrawalDelay = 5 minutes;
        slashingFreezeDuration = 730 days;

        delegationEnabled = false;
    }

    function setMinimumStake(uint96 newMinimumStake) external onlyOwner {
        minimumStake = newMinimumStake;
    }

    function setR2(uint48 newR2) external onlyOwner {
        R2 = newR2;
    }

    function setR1(uint32 newR1) external onlyOwner {
        R1 = newR1;
    }

    function setR0(uint32 newR0) external onlyOwner {
        R0 = newR0;
    }

    function setCommitWindowDuration(uint16 newCommitWindowDuration) external onlyOwner {
        commitWindowDuration = newCommitWindowDuration;
    }

    function setMinProofWindowOffsetPerc(uint8 newMinProofWindowOffsetPerc) external onlyOwner {
        minProofWindowOffsetPerc = newMinProofWindowOffsetPerc;
    }

    function setMaxProofWindowOffsetPerc(uint8 newMaxProofWindowOffsetPerc) external onlyOwner {
        maxProofWindowOffsetPerc = newMaxProofWindowOffsetPerc;
    }

    function setProofWindowDurationPerc(uint8 newProofWindowDurationPerc) external onlyOwner {
        proofWindowDurationPerc = newProofWindowDurationPerc;
    }

    function setReplacementWindowDurationPerc(uint8 newReplacementWindowDurationPerc) external onlyOwner {
        replacementWindowDurationPerc = newReplacementWindowDurationPerc;
    }

    function setEpochLength(uint128 newEpochLength) external onlyOwner {
        epochLength = newEpochLength;
    }

    function setStakeWithdrawalDelay(uint24 newStakeWithdrawalDelay) external onlyOwner {
        stakeWithdrawalDelay = newStakeWithdrawalDelay;
    }

    function setRewardWithdrawalDelay(uint24 newRewardWithdrawalDelay) external onlyOwner {
        rewardWithdrawalDelay = newRewardWithdrawalDelay;
    }

    function setSlashingFreezeDuration(uint32 newSlashingFreezeDuration) external onlyOwner {
        slashingFreezeDuration = newSlashingFreezeDuration;
    }

    function setDelegationEnabled(bool enabled) external onlyOwner {
        delegationEnabled = enabled;
    }

}
