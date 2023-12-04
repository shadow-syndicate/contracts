// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../Operators.sol";
import "../../interfaces/IRoachNFT.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Reveal genome using random genome from list
abstract contract Reveal is Operators {

    event GenomeUsed(uint index);

    IRoachNFT public roachContract;
    bytes[] public genomes;

    function _requestReveal(uint tokenId) internal virtual;

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function uploadGenomes(bytes[] calldata _genomes) external onlyOperator {
        for (uint i = 0; i < _genomes.length; i++) {
            genomes.push(_genomes[i]);
        }
    }

    function getGenome(uint index) external view returns (bytes memory genome) {
        return genomes[index];
    }

    function getGenomeCount() external view returns (uint genomeCount) {
        return genomes.length;
    }

    /// @notice Setups roach genome and give birth to it.
    function requestReveal(uint tokenId) external {
        address realOwner = roachContract.ownerOf(tokenId);
        require(realOwner == msg.sender, "Wrong egg owner");
        require(roachContract.canReveal(tokenId), "Already revealed");
        roachContract.lockOperator(tokenId);
        _requestReveal(tokenId);
    }

    function _withdrawGenome(uint seed) internal virtual returns (bytes memory genome) {
        require(genomes.length > 0, 'Out of genomes');
        uint index = seed % genomes.length;
        bytes storage result = genomes[index];
        genomes[index] = genomes[genomes.length - 1];
        genomes.pop();

        emit GenomeUsed(index);

        return result;
    }

    function revealCallback(uint tokenId, uint seed) internal {
        bytes memory genome = _withdrawGenome(seed);
        roachContract.revealOperator(tokenId, genome);
    }

}
