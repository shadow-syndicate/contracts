// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IGenomeProvider {
    function requestGenome(uint tokenId, uint8 traitBonus) external;
    function isReadyForReveal(uint tokenId) external view returns (bool);
    function reveal(uint tokenId) external;
}
