// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IRoachNFT {

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance) external;

    function mintGen0(address to, uint8 traitBonus, string calldata syndicate) external;

    function setGenome(uint tokenId, bytes calldata genome) external;

    function lastRoachId() external view returns (uint);

}
