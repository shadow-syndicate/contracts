// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC721/ERC721.sol";
import "./Operators.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/IGenomeProvider.sol";

contract RoachNFT is ERC721, Operators, IRoachNFT {

    struct Roach {
        bytes genome;
        uint40[2] parents;
        uint40 creationTime;
        uint40 birthTime;
        uint40 generation;
        uint16 resistance; // 1234 = 12.34%
    }

    Roach[] public roach;
    // uint public BIRTH_COOLDOWN = uint256(-1); // max int, will be changed to 7 week later
    uint public BIRTH_COOLDOWN = 1; // for debug only
    uint16 public GEN0_RESISTANCE = 10000; // 100%
    IMetadata public metadataContract;
    IGenomeProvider public genomeProviderContract;

    event Birth(uint tokenId);
    event MetadataContractChanged(IMetadata metadataContract);
    event GenomeProviderContractChanged(IGenomeProvider genomeProviderContract);

    constructor(IMetadata _metadataContract)
        ERC721('Roach Racing Club', 'ROACH')
    {
        _setMetadataContract(_metadataContract);

//        _mint(address(this), 0); // Mythical base parent for all Gen0 roaches
        roach.push(Roach(
            new bytes(0)/*EMPTY_GENOME*/,
            [uint40(0), uint40(0)], // parents
            uint40(0), // creationTime
            0, // birthTime
            0, // generation
            0  // resistance
        ));
    }

    function _mintRaw(
        address to,
        bytes memory genome,
        uint40[2] memory parents,
        uint40 generation,
        uint16 resistance,
        uint32 traitBonus
    ) internal {
        uint tokenId = roach.length;
        _mint(to, tokenId);
        roach.push(Roach(genome, parents, uint40(block.timestamp), 0, generation, resistance));
        genomeProviderContract.requestGenome(tokenId, traitBonus);
    }

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance
    ) external onlyOperator {
        _mintRaw(to, genome, parents, generation, resistance, 0);
    }

    function mintGen0(address to, uint32 traitBonus) external onlyOperator {
        _mintRaw(
            to,
            new bytes(0)/*EMPTY_GENOME*/,
            [uint40(0), uint40(0)], // parents
            0, // generation
            GEN0_RESISTANCE,
            traitBonus);
    }

    function setGenome(uint tokenId, bytes calldata genome) external onlyOperator {
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
        return r.genome.length > 0;
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

    // anyone can call
    function giveBirth(uint tokenId) external {
        require(_canBorn(tokenId), 'Still egg');
        roach[tokenId].birthTime = uint40(block.timestamp);
        emit Birth(tokenId);
    }

    // Metadata

    function _setMetadataContract(IMetadata newContract) internal {
        metadataContract = newContract;
        emit MetadataContractChanged(newContract);
    }

    function setMetadataContract(IMetadata newContract) external onlyOwner {
        _setMetadataContract(newContract);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        return metadataContract.tokenURI(tokenId);
    }

    // GenomeProvider

    function _setGenomeProviderContract(IGenomeProvider newContract) internal {
        _addOperator(address(newContract));
        genomeProviderContract = newContract;
        emit GenomeProviderContractChanged(newContract);
    }

    function setGenomeProviderContract(IGenomeProvider newContract) external onlyOwner {
        _setGenomeProviderContract(newContract);
    }

}
