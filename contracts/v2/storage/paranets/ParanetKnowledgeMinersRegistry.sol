// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {HubDependentV2} from "../../abstract/HubDependent.sol";
import {Named} from "../../../v1/interface/Named.sol";
import {Versioned} from "../../../v1/interface/Versioned.sol";
import {ParanetStructs} from "../../structs/paranets/ParanetStructs.sol";

contract ParanetKnowledgeMinersRegistry is Named, Versioned, HubDependentV2 {
    string private constant _NAME = "ParanetKnowledgeMinersRegistry";
    string private constant _VERSION = "2.0.0";

    // Address => Knowledge Miner Profile
    mapping(address => ParanetStructs.KnowledgeMiner) knowledgeMiners;

    // solhint-disable-next-line no-empty-blocks
    constructor(address hubAddress) HubDependentV2(hubAddress) {}

    function name() external pure virtual override returns (string memory) {
        return _NAME;
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
    }

    function registerKnowledgeMiner(address miner, bytes calldata metadata) external onlyContracts {
        ParanetStructs.KnowledgeMiner storage knowledgeMiner = knowledgeMiners[miner];

        knowledgeMiner.addr = miner;
        knowledgeMiner.metadata = metadata;
    }

    function deleteKnowledgeMiner(address miner) external onlyContracts {
        delete knowledgeMiners[miner];
    }

    function knowledgeMinerExists(address miner) external view returns (bool) {
        return knowledgeMiners[miner].addr == miner;
    }

    function getKnowledgeMinerMetadata(
        address addr
    ) external view returns (ParanetStructs.KnowledgeMinerMetadata memory) {
        return
            ParanetStructs.KnowledgeMinerMetadata({
                addr: addr,
                totalTracSpent: knowledgeMiners[addr].totalTracSpent,
                totalSubmittedKnowledgeAssetsCount: knowledgeMiners[addr].totalSubmittedKnowledgeAssetsCount,
                metadata: knowledgeMiners[addr].metadata
            });
    }

    function getTotalTracSpent(address miner) external view returns (uint96) {
        return knowledgeMiners[miner].totalTracSpent;
    }

    function setTotalTracSpent(address miner, uint96 totalTracSpent) external onlyContracts {
        knowledgeMiners[miner].totalTracSpent = totalTracSpent;
    }

    function addTotalTracSpent(address miner, uint96 addedTracSpent) external onlyContracts {
        knowledgeMiners[miner].totalTracSpent += addedTracSpent;
    }

    function subTotalTracSpent(address miner, uint96 subtractedTracSpent) external onlyContracts {
        knowledgeMiners[miner].totalTracSpent -= subtractedTracSpent;
    }

    function getTotalSubmittedKnowledgeAssetsCount(address miner) external view returns (uint256) {
        return knowledgeMiners[miner].totalSubmittedKnowledgeAssetsCount;
    }

    function setTotalSubmittedKnowledgeAssetsCount(
        address miner,
        uint256 totalSubmittedKnowledgeAssetsCount
    ) external onlyContracts {
        knowledgeMiners[miner].totalSubmittedKnowledgeAssetsCount = totalSubmittedKnowledgeAssetsCount;
    }

    function incrementTotalSubmittedKnowledgeAssetsCount(address miner) external onlyContracts {
        unchecked {
            knowledgeMiners[miner].totalSubmittedKnowledgeAssetsCount++;
        }
    }

    function decrementTotalSubmittedKnowledgeAssetsCount(address miner) external onlyContracts {
        unchecked {
            knowledgeMiners[miner].totalSubmittedKnowledgeAssetsCount--;
        }
    }

    function addSubmittedKnowledgeAsset(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetId
    ) external onlyContracts {
        knowledgeMiners[miner].submittedKnowledgeAssetsIndexes[paranetId][knowledgeAssetId] = knowledgeMiners[miner]
            .submittedKnowledgeAssets[paranetId]
            .length;
        knowledgeMiners[miner].submittedKnowledgeAssets[paranetId].push(knowledgeAssetId);
    }

    function removeSubmittedKnowledgeAsset(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetId
    ) external onlyContracts {
        // 1. Move the last element to the slot of the element to remove
        knowledgeMiners[miner].submittedKnowledgeAssets[paranetId][
            knowledgeMiners[miner].submittedKnowledgeAssetsIndexes[paranetId][knowledgeAssetId]
        ] = knowledgeMiners[miner].submittedKnowledgeAssets[paranetId][
            knowledgeMiners[miner].submittedKnowledgeAssets[paranetId].length - 1
        ];

        // 2. Update the index of the moved element
        knowledgeMiners[miner].submittedKnowledgeAssetsIndexes[paranetId][
            knowledgeMiners[miner].submittedKnowledgeAssets[paranetId][
                knowledgeMiners[miner].submittedKnowledgeAssets[paranetId].length - 1
            ]
        ] = knowledgeMiners[miner].submittedKnowledgeAssetsIndexes[paranetId][knowledgeAssetId];

        // 3. Remove the last element from the array
        knowledgeMiners[miner].submittedKnowledgeAssets[paranetId].pop();

        // 4. Delete the index of the removed element
        delete knowledgeMiners[miner].submittedKnowledgeAssetsIndexes[paranetId][knowledgeAssetId];
    }

    function getSubmittedKnowledgeAssets(address miner, bytes32 paranetId) external view returns (bytes32[] memory) {
        return knowledgeMiners[miner].submittedKnowledgeAssets[paranetId];
    }

    function getSubmittedKnowledgeAssets(
        address miner,
        bytes32 paranetId,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory) {
        require(start <= end, "Start should be <= End");
        require(
            end <= knowledgeMiners[miner].submittedKnowledgeAssets[paranetId].length,
            "End should be <= length of Array"
        );

        bytes32[] memory slice = new bytes32[](end - start);
        for (uint i; i < slice.length; ) {
            slice[i] = knowledgeMiners[miner].submittedKnowledgeAssets[paranetId][i];

            unchecked {
                i++;
            }
        }

        return slice;
    }

    function addUpdatingKnowledgeAssetState(
        address miner,
        bytes32 paranetId,
        address knowledgeAssetStorageContract,
        uint256 tokenId,
        bytes32 assertionId,
        uint96 updateTokenAmount
    ) external onlyContracts {
        knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][
            keccak256(abi.encodePacked(knowledgeAssetStorageContract, tokenId, assertionId))
        ] = knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length;

        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].push(
            ParanetStructs.UpdatingKnowledgeAssetState({
                knowledgeAssetStorageContract: knowledgeAssetStorageContract,
                tokenId: tokenId,
                assertionId: assertionId,
                updateTokenAmount: updateTokenAmount
            })
        );
    }

    function removeUpdatingKnowledgeAssetState(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetStateId
    ) external onlyContracts {
        // 1. Move the last element to the slot of the element to remove
        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId][
            knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId]
        ] = knowledgeMiners[miner].updatingKnowledgeAssets[paranetId][
            knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length - 1
        ];

        // 2. Update the index of the moved element
        knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][
            keccak256(
                abi.encodePacked(
                    knowledgeMiners[miner]
                    .updatingKnowledgeAssets[paranetId][
                        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length - 1
                    ].knowledgeAssetStorageContract,
                    knowledgeMiners[miner]
                    .updatingKnowledgeAssets[paranetId][
                        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length - 1
                    ].tokenId,
                    knowledgeMiners[miner]
                    .updatingKnowledgeAssets[paranetId][
                        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length - 1
                    ].assertionId
                )
            )
        ] = knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId];

        // 3. Remove the last element from the array
        knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].pop();

        // 4. Delete the index of the removed element
        delete knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId];
    }

    function getUpdatingKnowledgeAssetStates(
        address miner,
        bytes32 paranetId
    ) external view returns (ParanetStructs.UpdatingKnowledgeAssetState[] memory) {
        return knowledgeMiners[miner].updatingKnowledgeAssets[paranetId];
    }

    function getUpdatingKnowledgeAssetStates(
        address miner,
        bytes32 paranetId,
        uint256 start,
        uint256 end
    ) external view returns (ParanetStructs.UpdatingKnowledgeAssetState[] memory) {
        require(start <= end, "Start should be <= End");
        require(
            end <= knowledgeMiners[miner].updatingKnowledgeAssets[paranetId].length,
            "End should be <= length of Array"
        );

        ParanetStructs.UpdatingKnowledgeAssetState[] memory slice = new ParanetStructs.UpdatingKnowledgeAssetState[](
            end - start
        );
        for (uint i; i < slice.length; ) {
            slice[i] = knowledgeMiners[miner].updatingKnowledgeAssets[paranetId][i];

            unchecked {
                i++;
            }
        }

        return slice;
    }

    function setUpdatingKnowledgeAssetUpdateTokenAmount(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetStateId,
        uint96 updateTokenAmount
    ) external onlyContracts {
        knowledgeMiners[miner]
        .updatingKnowledgeAssets[paranetId][
            knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId]
        ].updateTokenAmount = updateTokenAmount;
    }

    function addUpdatingKnowledgeAssetUpdateTokenAmount(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetStateId,
        uint96 addedUpdateTokenAmount
    ) external onlyContracts {
        knowledgeMiners[miner]
        .updatingKnowledgeAssets[paranetId][
            knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId]
        ].updateTokenAmount += addedUpdateTokenAmount;
    }

    function subUpdatingKnowledgeAssetUpdateTokenAmount(
        address miner,
        bytes32 paranetId,
        bytes32 knowledgeAssetStateId,
        uint96 subtractedUpdateTokenAmount
    ) external onlyContracts {
        knowledgeMiners[miner]
        .updatingKnowledgeAssets[paranetId][
            knowledgeMiners[miner].updatingKnowledgeAssetsIndexes[paranetId][knowledgeAssetStateId]
        ].updateTokenAmount -= subtractedUpdateTokenAmount;
    }

    function getCumulativeTracSpent(address miner, bytes32 paranetId) external view returns (uint96) {
        return knowledgeMiners[miner].cumulativeTracSpent[paranetId];
    }

    function setCumulativeTracSpent(
        address miner,
        bytes32 paranetId,
        uint96 cumulativeTracSpent
    ) external onlyContracts {
        knowledgeMiners[miner].cumulativeTracSpent[paranetId] = cumulativeTracSpent;
    }

    function addCumulativeTracSpent(address miner, bytes32 paranetId, uint96 addedTracSpent) external onlyContracts {
        knowledgeMiners[miner].cumulativeTracSpent[paranetId] += addedTracSpent;
    }

    function subCumulativeTracSpent(
        address miner,
        bytes32 paranetId,
        uint96 subtractedTracSpent
    ) external onlyContracts {
        knowledgeMiners[miner].cumulativeTracSpent[paranetId] -= subtractedTracSpent;
    }

    function getUnrewardedTracSpent(address miner, bytes32 paranetId) external view returns (uint96) {
        return knowledgeMiners[miner].unrewardedTracSpent[paranetId];
    }

    function setUnrewardedTracSpent(
        address miner,
        bytes32 paranetId,
        uint96 unrewardedTracSpent
    ) external onlyContracts {
        knowledgeMiners[miner].unrewardedTracSpent[paranetId] = unrewardedTracSpent;
    }

    function addUnrewardedTracSpent(
        address miner,
        bytes32 paranetId,
        uint96 addedUnrewardedTracSpent
    ) external onlyContracts {
        knowledgeMiners[miner].unrewardedTracSpent[paranetId] += addedUnrewardedTracSpent;
    }

    function subUnrewardedTracSpent(
        address miner,
        bytes32 paranetId,
        uint96 subtractedUnrewardedTracSpent
    ) external onlyContracts {
        knowledgeMiners[miner].unrewardedTracSpent[paranetId] -= subtractedUnrewardedTracSpent;
    }

    function getCumulativeAwardedNeuro(address miner, bytes32 paranetId) external view returns (uint256) {
        return knowledgeMiners[miner].cumulativeAwardedNeuro[paranetId];
    }

    function setCumulativeAwardedNeuro(
        address miner,
        bytes32 paranetId,
        uint256 cumulativeAwardedNeuro
    ) external onlyContracts {
        knowledgeMiners[miner].cumulativeAwardedNeuro[paranetId] = cumulativeAwardedNeuro;
    }

    function addCumulativeAwardedNeuro(
        address miner,
        bytes32 paranetId,
        uint256 addedCumulativeAwardedNeuro
    ) external onlyContracts {
        knowledgeMiners[miner].cumulativeAwardedNeuro[paranetId] += addedCumulativeAwardedNeuro;
    }

    function subCumulativeAwardedNeuro(
        address miner,
        bytes32 paranetId,
        uint256 subtractedCumulativeAwardedNeuro
    ) external onlyContracts {
        knowledgeMiners[miner].cumulativeAwardedNeuro[paranetId] -= subtractedCumulativeAwardedNeuro;
    }
}
