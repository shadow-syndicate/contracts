// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC721/ERC721.sol";
import "./Operators.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IRoachNFT.sol";

// TODO: liquidation
// TODO: rent, approve
// TODO: bridge
contract RoachNFT is ERC721, Operators, IRoachNFT {

    struct Roach {
        bytes genome;
        uint40[2] parents;
        uint40 creationTime;
        uint40 revealTime;
        uint40 generation;
        uint16 resistance; // 1234 = 12.34%
    }

    mapping(uint => Roach) public roach;
    uint16 public GEN0_RESISTANCE = 10000; // 100%
    IMetadata public metadataContract;
    address public signerAddress;
    uint lastTokenId = 0;

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
    }

    // TODO: batch
    function getRoach(uint roachId)
        external view
        returns (
            bytes memory genome,
            uint40[2] memory parents,
            uint40 creationTime,
            uint40 revealTime,
            uint40 generation,
            uint16 resistance,
            string memory name)
    {
        require(_exists(roachId), "query for nonexistent token");
        Roach storage r = roach[roachId];
        genome = r.genome;
        parents = r.parents;
        creationTime = r.creationTime;
        revealTime = r.revealTime;
        generation = r.generation;
        resistance = r.generation == 0 ? GEN0_RESISTANCE : r.resistance;
        name = metadataContract.getName(roachId);
    }

    function getGenome(uint roachId) external view returns (bytes memory genome) {
        require(_exists(roachId), "query for nonexistent token");
        Roach storage r = roach[roachId];
        genome = r.genome;
    }

    function lastRoachId() external view returns (uint) {
        return _lastRoachId();
    }

    function _lastRoachId() internal view returns (uint) {
        return lastTokenId;
    }

    // for gen1 and offsprings
    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance
    ) external onlyOperator {
        lastTokenId++;
        _mint(to, lastTokenId);
        roach[lastTokenId] = Roach(genome, parents, uint40(block.timestamp), 0, generation, resistance);
    }

    function mintGen0(address to, uint count, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        for (uint i = 0; i < count; i++) {
            lastTokenId++;
            _mint(to, lastTokenId);
//            roach[lastTokenId] = Roach(
//                new bytes(0)/*EMPTY_GENOME*/,
//                parents,
//                uint40(block.timestamp),
//                0,
//                generation,
//                resistance);
            emit Mint(to, lastTokenId, traitBonus, syndicate);
        }
    }

    function burn(uint tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function setGenome(uint tokenId, bytes calldata genome) external onlyOperator {
        _setGenome(tokenId, genome);
    }

    function _setGenome(uint tokenId, bytes calldata genome) internal {
        require(_exists(tokenId), "RoachNFT.setGenome: nonexistent token");
        roach[tokenId].genome = genome;
        emit GenomeChanged(tokenId, genome);
    }

    function canReveal(uint tokenId) external view returns (bool) {
        return _canReveal(tokenId);
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
            !_isRevealed(r);
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

    // TODO: publish token_seed
    function reveal(uint tokenId, bytes calldata genome, uint token_seed, uint8 sigV, bytes32 sigR, bytes32 sigS) external {
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
        if (roach[tokenId].generation == 0 && roach[tokenId].resistance == 0) {
            // fill resistance because roach[tokenId] is empty
            roach[tokenId].resistance = GEN0_RESISTANCE;
        }
        emit Reveal(ownerOf(tokenId), tokenId);
        _setGenome(tokenId, genome);
    }

    // Enumerable

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256 tokenId)
    {
        uint40 count = 0;
        for (uint40 i = 1; i <= _lastRoachId(); ++i) {
            if (ownerOf(i) == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

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
