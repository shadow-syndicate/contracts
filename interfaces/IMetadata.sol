// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
