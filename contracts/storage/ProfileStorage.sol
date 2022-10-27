// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Hub} from '../Hub.sol';

contract ProfileStorage {
    event AskUpdated(bytes nodeId, uint256 ask);
    event StakeUpdated(bytes nodeId, uint256 stake);

    Hub public hub;
    
    constructor(address hubAddress) {
        hub = Hub(hubAddress);
        activeNodes = 1;
    }

    function setHubAddress(address newHubAddress)
    public onlyContracts {
        require(newHubAddress != address(0));
        hub = Hub(newHubAddress);
    }
    
    modifier onlyContracts(){
        require(hub.isContract(msg.sender),
        "Function can only be called by contracts!");
        _;
    }

    uint256 public activeNodes;

    function setActiveNodes(uint256 newActiveNodes) 
    public onlyContracts {
        activeNodes = newActiveNodes;
    }

    struct ProfileDefinition{
        uint256 ask;
        uint256 stake;
        uint256 stakeReserved;
        uint256 reputation;
        bool withdrawalPending;
        uint256 withdrawalTimestamp;
        uint256 withdrawalAmount;
        bytes nodeId;
    }
    mapping(address => ProfileDefinition) public profile;

    function getAsk(address identity)
    public view returns(uint256) {
        return profile[identity].ask;
    }

    function getStake(address identity) 
    public view returns(uint256) {
        return profile[identity].stake;
    }
    function getStakeReserved(address identity) 
    public view returns(uint256) {
        return profile[identity].stakeReserved;
    }
    function getReputation(address identity) 
    public view returns(uint256) {
        return profile[identity].reputation;
    }
    function getWithdrawalPending(address identity) 
    public view returns(bool) {
        return profile[identity].withdrawalPending;
    }
    function getWithdrawalTimestamp(address identity) 
    public view returns(uint256) {
        return profile[identity].withdrawalTimestamp;
    }
    function getWithdrawalAmount(address identity) 
    public view returns(uint256) {
        return profile[identity].withdrawalAmount;
    }
    function getNodeId(address identity) 
    public view returns(bytes memory) {
        return profile[identity].nodeId;
    }

    function setAsk(address identity, uint256 ask)
    public onlyContracts {
        profile[identity].ask = ask;

        emit AskUpdated(this.getNodeId(identity), ask);
    }
    
    function setStake(address identity, uint256 stake) 
    public onlyContracts {
        profile[identity].stake = stake;

        emit StakeUpdated(this.getNodeId(identity), stake);
    }
    function setStakeReserved(address identity, uint256 stakeReserved) 
    public onlyContracts {
        profile[identity].stakeReserved = stakeReserved;
    }
    function setReputation(address identity, uint256 reputation) 
    public onlyContracts {
        profile[identity].reputation = reputation;
    }
    function setWithdrawalPending(address identity, bool withdrawalPending) 
    public onlyContracts {
        profile[identity].withdrawalPending = withdrawalPending;
    }
    function setWithdrawalTimestamp(address identity, uint256 withdrawalTimestamp) 
    public onlyContracts {
        profile[identity].withdrawalTimestamp = withdrawalTimestamp;
    }
    function setWithdrawalAmount(address identity, uint256 withdrawalAmount) 
    public onlyContracts {
        profile[identity].withdrawalAmount = withdrawalAmount;
    }
    function setNodeId(address identity, bytes memory nodeId)
    public onlyContracts {
        profile[identity].nodeId = nodeId;
    }

    function increaseStakesReserved(
        address payer,
        address identity1,
        address identity2,
        address identity3,
        uint256 amount)
    public onlyContracts {
        require(identity1!=address(0) && identity2!=address(0) && identity3!=address(0));
        profile[payer].stakeReserved += (amount * 3);
        profile[identity1].stakeReserved += amount;
        profile[identity2].stakeReserved += amount;
        profile[identity3].stakeReserved += amount;
    }

    function transferTokens(address wallet, uint256 amount)
    public onlyContracts {
        ERC20 token = ERC20(hub.getContractAddress("Token"));
        token.transfer(wallet, amount);
    }
}
