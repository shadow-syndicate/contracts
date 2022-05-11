// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IRoachNFT {

    function mintGen0(address to, uint count, uint8 traitBonus, string calldata syndicate) external;

    function setGenome(uint tokenId, bytes calldata genome) external;

    function lastRoachId() external view returns (uint);

    function getNumberMinted(address account) external view returns (uint64);

}
