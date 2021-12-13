// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC721/ERC721.sol";
import "./Operators.sol";
import "./Metadata.sol";
import "../interfaces/RoachNFTInterface.sol";

contract RoachNFT is ERC721, Operators, RoachNFTInterface {

    struct Roach {
        Genome genome;
        uint40[2] parents;
        uint40 creationTime;
        uint40 birthTime;
    }

    Roach[] public roach;
    // uint public BIRTH_COOLDOWN = uint256(-1); // max int, will be changed to 7 week later
    uint public BIRTH_COOLDOWN = 1; // for debug only
    uint constant public EMPTY_GENOME = 0;
    Metadata public metadataContract;

    event Birth(uint tokenId);
    event MetadataContractChanged(Metadata metadataContract);

    constructor(Metadata _metadataContract) ERC721('Roach Racing Club', 'ROACH') {
        _setMetadataContract(_metadataContract);

        _mint(address(0x0), 0); // Mythical base parent for all Gen0 roaches
        roach[0] = Roach(Genome.wrap(EMPTY_GENOME), [uint40(0), uint40(0)], uint40(0), 0);
    }

    function _mintRaw(address to, Genome genome, uint40[2] memory parents) internal {
        uint tokenId = roach.length;
        _mint(to, tokenId);
        roach[tokenId] = Roach(genome, parents, uint40(block.timestamp), 0);
    }

    function mint(address to, Genome genome, uint40[2] calldata parents) external onlyOperator {
        _mintRaw(to, genome, parents);
    }

    function mintGen0(address to) external onlyOperator {
        _mintRaw(to, Genome.wrap(EMPTY_GENOME), [uint40(0), uint40(0)]);
    }

    function setGenome(uint tokenId, Genome genome) external onlyOperator {
        require(_exists(tokenId), "RoachNFT.setGenome: nonexistent token");
        roach[tokenId].genome = genome;
    }

    function setBirthCooldown(uint newCooldown) external onlyOwner {
        BIRTH_COOLDOWN = newCooldown;
    }

    function canBorn(uint tokenId) external view returns (bool) {
        return _canBorn(tokenId);
    }

    function _isGenomeSet(Roach storage r) internal view returns (bool) {
        return Genome.unwrap(r.genome) != EMPTY_GENOME;
    }

    function _isBirthColdownPassed(Roach storage r) internal view returns (bool) {
        return r.creationTime + BIRTH_COOLDOWN <= block.timestamp;
    }

    function _canBorn(uint tokenId) internal view returns (bool) {
        Roach storage r = roach[tokenId];
        return
            _isGenomeSet(r) &&
            _isBirthColdownPassed(r);
    }

    function giveBirth(uint tokenId) external {
        require(_canBorn(tokenId), 'Still egg');
        roach[tokenId].birthTime = uint40(block.timestamp);
        emit Birth(tokenId);
    }


    // Metadata

    function _setMetadataContract(Metadata newContract) internal {
        metadataContract = newContract;
        emit MetadataContractChanged(newContract);
    }

    function setMetadataContract(Metadata newContract) external onlyOwner {
        _setMetadataContract(newContract);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        return metadataContract.tokenURI(tokenId);
    }

}
