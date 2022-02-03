// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IRoachNFT {

    function mint(
        address to,
        uint256[] calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance) external;
    function mintGen0(address to, uint32 traitBonus) external;
    function setGenome(uint tokenId, uint256[] calldata genome) external;

}
