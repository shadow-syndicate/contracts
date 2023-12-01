// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Reveal.sol";
import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Reveal genome using random genome from list
contract RevealChainlink is Reveal, VRFConsumerBaseV2 {
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;
    uint64 subscriptionId;
    VRFCoordinatorV2Interface vrfCoordinator;
    uint32 constant callbackGasLimit = 2_000_000;
    uint16 constant requestConfirmations = 1;
    mapping(uint => uint) public requests;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        IRoachNFT _roachContract,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint64 _subscriptionId
    )
        Reveal(_roachContract)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkKeyHash = _chainLinkKeyHash;
        subscriptionId = _subscriptionId;
    }

    function _requestReveal(uint tokenId) internal override {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            chainLinkKeyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1);
        requests[requestId] = tokenId;
    }

    /// @notice ChainlinkVRF callback function with supplied randomness
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint tokenId = requests[requestId];
        delete requests[requestId];
        revealCallback(tokenId, randomWords[0]);
    }
}
