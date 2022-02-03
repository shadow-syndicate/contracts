// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

type Genome is uint256;

interface IRoachNFT {

    function mint(address to, Genome genome, uint40[2] calldata parents) external;
    function mintGen0(address to, uint32 traitBonus) external;
    function setGenome(uint tokenId, Genome genome) external;

}
