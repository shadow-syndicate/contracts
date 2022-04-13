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

    function mintGen0(address to, uint8 traitBonus) external;

    function setGenome(uint tokenId, bytes calldata genome) external;

    function getRoach(uint roachId)
        external view
    returns (
        bytes memory genome,
        uint40[2] memory parents,
        uint40 creationTime,
        uint40 canBirthTime,
        uint40 birthTime,
        uint40 generation,
        uint16 resistance,
        string memory name);

    function getGenome(uint roachId) external view returns (bytes memory genome);
}
