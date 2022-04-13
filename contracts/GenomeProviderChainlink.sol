// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenomeProvider.sol";
import "smartcontractkit/chainlink@1.2.1/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "smartcontractkit/chainlink@1.2.1/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


contract GenomeProviderChainlink is GenomeProvider, VRFConsumerBaseV2 {
    bytes32 chainLinkKeyHash;
    uint64 subscriptionId;
    VRFCoordinatorV2Interface coordinator;
    uint16 requestConfirmations;
    mapping (uint256 => uint) public linkRequestIdToTokenId;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        IRoachNFT _roachContract,
        VRFCoordinatorV2Interface _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint64 _subscriptionId,
        uint16 _requestConfirmations
    )
        GenomeProvider(_roachContract)
        VRFConsumerBaseV2(address(_vrfCoordinator))
    {
        chainLinkKeyHash = _chainLinkKeyHash;
        coordinator = _vrfCoordinator;
        subscriptionId = _subscriptionId;
        requestConfirmations = _requestConfirmations;
    }

    function _requestRandomness(uint256 _tokenId) internal override {
        uint256 requestId = coordinator.requestRandomWords(
            chainLinkKeyHash,
            subscriptionId,
            requestConfirmations,
            500000,
            1);
        linkRequestIdToTokenId[requestId] = _tokenId;
    }

    // callback function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        uint tokenId = linkRequestIdToTokenId[requestId];
        delete linkRequestIdToTokenId[requestId];
        _onRandomnessArrived(tokenId, randomness[0]);
    }
}
