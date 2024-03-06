// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "./GenesisMint2.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Reveal genome using random genome from list
contract GenesisMint2Chainlink is GenesisMint2, VRFConsumerBaseV2 {
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;
    uint64 subscriptionId;
    VRFCoordinatorV2Interface vrfCoordinator;
    uint32 constant callbackGasLimit = 2_000_000;
    uint16 constant requestConfirmations = 3;
    mapping(uint => address) public requests;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken,
        uint stage1startTime,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint64 _subscriptionId
    )
        GenesisMint2(_roachContract, _traxToken, stage1startTime)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkKeyHash = _chainLinkKeyHash;
        subscriptionId = _subscriptionId;
    }

    function _requestRandomForMint(address account) internal override returns (uint256 requestId) {
        requestId = vrfCoordinator.requestRandomWords(
            chainLinkKeyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1);
        requests[requestId] = account;
    }

    /// @notice ChainlinkVRF callback function with supplied randomness
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address account = requests[requestId];
        delete requests[requestId];
        _randomCallback(account, randomWords[0], requestId);
    }
}
