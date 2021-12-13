// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../interfaces/IGenomeProvider.sol";
import "../interfaces/IRoachNFT.sol";
import "smartcontractkit/chainlink@0.10.15/contracts/src/v0.8/VRFConsumerBase.sol";

contract GenomeProvider is IGenomeProvider, VRFConsumerBase {

    IRoachNFT roachContract;
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;
    mapping (bytes32 => uint) public linkRequestId;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        IRoachNFT _roachContract,
        address _link,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint256 _chainLinkFee
    )
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        roachContract = _roachContract;
        chainLinkFee = _chainLinkFee;
        chainLinkKeyHash = _chainLinkKeyHash;
    }


    function requestGenome(uint tokenId) external {
        require(msg.sender == address(roachContract), 'Access denied');
        _requestGenome(tokenId);
    }

    function _requestGenome(uint256 _tokenId) internal {
        require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK to pay fee");
        bytes32 requestId = requestRandomness(chainLinkKeyHash, chainLinkFee);
        linkRequestId[requestId] = _tokenId;
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    )
        internal
        override
    {
        uint tokenId = linkRequestId[requestId];
        delete linkRequestId[requestId];
        // If randomness will be 0, your unlucky tree will not be alive
        _onGenomeArrived(tokenId, randomness);
    }

    function _onGenomeArrived(uint256 _tokenId, uint256 _randomness) internal {

        Genome genome = _normalizeGenome(_randomness);

        roachContract.setGenome(_tokenId, genome);
    }

    function _normalizeGenome(uint256 _randomness) internal returns (Genome) {
        return Genome.wrap(_randomness); // TODO: fix genome
    }

}
