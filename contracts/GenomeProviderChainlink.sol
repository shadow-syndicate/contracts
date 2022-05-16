// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenomeProviderPolygon.sol";
import "smartcontractkit/chainlink@1.2.1/contracts/src/v0.8/VRFConsumerBase.sol";
import "smartcontractkit/chainlink@1.2.1/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @title Genome generator
/// @author Shadow Syndicate / Andrey Pelipenko (kindex@kindex.lv)
/// @dev Production version of GenomeProvider that used real Chainlink VRF
contract GenomeProviderChainlink is GenomeProviderPolygon, VRFConsumerBase {
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        uint256 _secret_seed_hash,
        address _link,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint256 _chainLinkFee
    )
        GenomeProviderPolygon(_secret_seed_hash)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        chainLinkFee = _chainLinkFee;
        chainLinkKeyHash = _chainLinkKeyHash;
    }

    function _requestRandomness() internal override {
        require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK to pay fee");
        bytes32 requestId = requestRandomness(chainLinkKeyHash, chainLinkFee);
    }

    // callback function
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _onRandomnessArrived(randomness);
    }
}
