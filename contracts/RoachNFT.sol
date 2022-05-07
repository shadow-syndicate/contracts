// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Operators.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IRoachNFT.sol";

// TODO: liquidation
// TODO: rent, approve
// TODO: bridge
contract RoachNFT is ERC721Enumerable, Operators, IRoachNFT {

    struct Roach {
        bytes genome;
        uint40[2] parents;
        uint40 creationTime;
        uint40 revealTime;
        uint40 generation;
        uint16 resistance; // 1234 = 12.34%
    }

    Roach[] public roach;
    uint public REVEAL_COOLDOWN = 5 minutes; // TODO: change to 1 week
    uint16 public GEN0_RESISTANCE = 10000; // 100%
    IMetadata public metadataContract;
    address public signerAddress;

    event Mint(address indexed account, uint indexed tokenId, uint traitBonus, string syndicate);
    event Reveal(address indexed owner, uint indexed tokenId);
    event GenomeChanged(uint indexed tokenId, bytes genome);

    event MetadataContractChanged(IMetadata metadataContract);

    constructor(IMetadata _metadataContract)
        ERC721('RCH', 'R')
    {
        _setMetadataContract(_metadataContract);
        // TODO: setSigner
        signerAddress = msg.sender;

//        _mint(address(this), 0); // Mythical base parent for all Gen0 roaches
        roach.push(Roach(
            new bytes(0)/*EMPTY_GENOME*/,
            [uint40(0), uint40(0)], // parents
            uint40(0), // creationTime
            0, // revealTime
            0, // generation
            0  // resistance
        ));
    }

    // TODO: batch
    function getRoach(uint roachId)
        external view
        returns (
            bytes memory genome,
            uint40[2] memory parents,
            uint40 creationTime,
            uint40 canRevealTime,
            uint40 revealTime,
            uint40 generation,
            uint16 resistance,
            string memory name)
    {
        require(roachId < roach.length, "Non existing token");
        Roach storage r = roach[roachId];
        genome = r.genome;
        parents = r.parents;
        creationTime = r.creationTime;
        canRevealTime = r.creationTime + uint40(REVEAL_COOLDOWN);
        revealTime = r.revealTime;
        generation = r.generation;
        resistance = r.resistance;
        name = metadataContract.getName(roachId);
    }

    function getGenome(uint roachId) external view returns (bytes memory genome) {
        require(roachId <= roach.length, "Non existing token");
        Roach storage r = roach[roachId];
        genome = r.genome;
    }

    function lastRoachId() external view returns (uint) {
        return roach.length - 1;
    }

    function _mint(
        address to,
        uint40[2] memory parents,
        uint40 generation,
        uint16 resistance,
        uint8 traitBonus,
        string calldata syndicate
    ) internal {
        uint tokenId = roach.length;
        _mint(to, tokenId);
        roach.push(Roach(new bytes(0)/*EMPTY_GENOME*/, parents, uint40(block.timestamp), 0, generation, resistance));
        emit Mint(to, tokenId, traitBonus, syndicate);
    }

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance
    ) external onlyOperator {
        uint tokenId = roach.length;
        _mint(to, tokenId);
        roach.push(Roach(genome, parents, uint40(block.timestamp), 0, generation, resistance));
    }

    function mintGen0(address to, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        _mint(
            to,
            [uint40(0), uint40(0)], // parents
            0, // generation
            GEN0_RESISTANCE,
            traitBonus,
            syndicate);
    }

    function setGenome(uint tokenId, bytes calldata genome) external onlyOperator {
        _setGenome(tokenId, genome);
    }

    function _setGenome(uint tokenId, bytes calldata genome) internal {
        require(_exists(tokenId), "RoachNFT.setGenome: nonexistent token");
        roach[tokenId].genome = genome;
        emit GenomeChanged(tokenId, genome);
    }

    function setRevealCooldown(uint newCooldown) external onlyOwner {
        REVEAL_COOLDOWN = newCooldown;
    }

    function canReveal(uint tokenId) external view returns (bool) {
        return _canReveal(tokenId);
    }

    function _isRevealCooldownPassed(Roach storage r) internal view returns (bool) {
        return r.creationTime + REVEAL_COOLDOWN <= block.timestamp;
    }

    function isRevealed(uint tokenId) external view returns (bool) {
        Roach storage r = roach[tokenId];
        return _isRevealed(r);
    }

    function _isRevealed(Roach storage r) internal view returns (bool) {
        return r.revealTime > 0;
    }

    function _canReveal(uint tokenId) internal view returns (bool) {
        Roach storage r = roach[tokenId];
        return
            !_isRevealed(r) &&
            _isRevealCooldownPassed(r);
    }

    function revealBatch(uint[] calldata tokenIds, bytes[] calldata genome, uint8 v, bytes32 r, bytes32 s) external {
        // TODO: checkSignature
        require(false, "Not implemented");
        for (uint i = 0; i < tokenIds.length; i++) {
            _reveal(tokenIds[i], genome[i]);
        }
    }

    function hashArguments(
        uint tokenId, bytes calldata genome)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(tokenId, genome));
    }

    function getSigner(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(tokenId, genome);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    function isValidSignature(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(tokenId, genome, sigV, sigR, sigS) == signerAddress;
    }

    function reveal(uint tokenId, bytes calldata genome, uint8 sigV, bytes32 sigR, bytes32 sigS) external {
        require(ownerOf(tokenId) == msg.sender, "Wrong egg owner");
        require(isValidSignature(tokenId, genome, sigV, sigR, sigS), "Wrong signature");
        _reveal(tokenId, genome);
    }

    function revealOperator(uint tokenId, bytes calldata genome) external onlyOperator {
        _reveal(tokenId, genome);
    }

    function _reveal(uint tokenId, bytes calldata genome) internal {
        require(_canReveal(tokenId), 'Not ready for reveal');
        roach[tokenId].revealTime = uint40(block.timestamp);
        emit Reveal(ownerOf(tokenId), tokenId);
        _setGenome(tokenId, genome);
    }

    // Enumerable

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    // Metadata

    function setMetadataContract(IMetadata newContract) external onlyOwner {
        _setMetadataContract(newContract);
    }

    function _setMetadataContract(IMetadata newContract) internal {
        metadataContract = newContract;
        emit MetadataContractChanged(newContract);
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        return metadataContract.tokenURI(tokenId);
    }

    function contractURI() external view returns (string memory) {
        return metadataContract.contractURI();
    }

}
