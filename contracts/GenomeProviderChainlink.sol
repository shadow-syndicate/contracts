// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenomeProvider.sol";
import "smartcontractkit/chainlink@0.10.15/contracts/src/v0.8/VRFConsumerBase.sol";


contract GenomeProviderChainlink is GenomeProvider, VRFConsumerBase {
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;
    mapping (bytes32 => uint) public linkRequestId;
    mapping (bytes32 => uint32) public requestIdToTraitBonus;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        IRoachNFT _roachContract,
        address _link,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint256 _chainLinkFee
    )
        GenomeProvider(_roachContract)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        roachContract = _roachContract;
        chainLinkFee = _chainLinkFee;
        chainLinkKeyHash = _chainLinkKeyHash;
    }

    function _requestGenome(uint256 _tokenId, uint32 _traitBonus) internal override {
        require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK to pay fee");
        bytes32 requestId = requestRandomness(chainLinkKeyHash, chainLinkFee);
        linkRequestId[requestId] = _tokenId;
        requestIdToTraitBonus[requestId] = _traitBonus;
    }

    // callback function
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint tokenId = linkRequestId[requestId];
        uint32 traitBonus = requestIdToTraitBonus[requestId];
        delete linkRequestId[requestId];
        delete requestIdToTraitBonus[requestId];
        // If randomness will be 0, your unlucky tree will not be alive
        _onGenomeArrived(tokenId, randomness, traitBonus);
    }
}
