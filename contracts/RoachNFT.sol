// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./ERC721A/ERC721A.sol";
import "./Operators.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IRoachNFT.sol";

// TODO: liquidation
// TODO: rent, approve
// TODO: bridge


/// @title Roach Racing Club NFT registry
/// @author Shadow Syndicate / Andrey Pelipenko (kindex@kindex.lv)
/// @dev Stores NFT ownership and metadata like genome and parents.
///      Uses ERC-721A implementation to optimize gas consumptions during batch mints.
contract RoachNFT is ERC721A, Operators, IRoachNFT {

    struct Roach {
        // array of genes in secret format
        bytes genome;
        // NFT id of parents
        uint40[2] parents;
        // UNIX time when egg was minted
        uint40 creationTime;
        // UNIX time when egg was revealed to roach
        uint40 revealTime;
        // Gen0, Gen1, etc
        uint40 generation;
        // Resistance percentage (1234 = 12.34%)
        uint16 resistance;
    }

    mapping(uint => Roach) public roach;
    uint16 public GEN0_RESISTANCE = 10000; // 100%
    IMetadata public metadataContract;
    address public signerAddress;

    event Mint(address indexed account, uint indexed tokenId, uint traitBonus, string syndicate);
    event Reveal(address indexed owner, uint indexed tokenId);
    event GenomeChanged(uint indexed tokenId, bytes genome);

    event MetadataContractChanged(IMetadata metadataContract);

    constructor(IMetadata _metadataContract)
        ERC721A('RCH', 'R')
    {
        _setMetadataContract(_metadataContract);
        // TODO: setSigner
        signerAddress = msg.sender;
    }

    /// @dev Token numeration starts from 1 (genesis collection id 1..10k)
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // TODO: batch getRoach

    /// @notice Returns contract level metadata for roach
    /// @return genome       Array of genes in secret format
    /// @return parents      Array of 2 parent roach id
    /// @return creationTime UNIX time when egg was minted
    /// @return revealTime   UNIX time when egg was revealed to roach
    /// @return generation   Gen0, Gen1, etc
    /// @return resistance   Resistance percentage (1234 = 12.34%)
    /// @return name         Roach name
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

    /// @notice Total number of minted tokens for account
    function getNumberMinted(address account) external view returns (uint64) {
        return _numberMinted(account);
    }

    /// @notice lastRoachId doesn't equap totalSupply because some token will be burned
    ///         in using Run or Die mechanic
    function lastRoachId() external view returns (uint) {
        return _lastRoachId();
    }

    function _lastRoachId() internal view returns (uint) {
        return _currentIndex - 1;
    }

    /// @notice Mints new token with autoincremented index
    /// @dev Only for gen0 offsprings (gen1+)
    /// @dev Can be called only by authorized operator (breding contract)
    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance
    ) external onlyOperator {
        roach[_currentIndex] = Roach(genome, parents, uint40(block.timestamp), 0, generation, resistance);
        _mint(to, 1);
    }

    /// @notice Mints new token with autoincremented index and stores traitBonus/syndicate for reveal
    /// @dev Only for gen0
    /// @dev Can be called only by authorized operator (GenesisSale contract)
    function mintGen0(address to, uint count, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        uint tokenId = _currentIndex + 1;
        _mint(to, count);
        for (uint i = 0; i < count; i++) {
            // do not save Roach struct to mapping for Gen0 because all data is default
            emit Mint(to, tokenId + i, traitBonus, syndicate);
        }
    }

    /// @notice Owner can burn his token
    function burn(uint tokenId) external {
        _burn(tokenId, true);
    }

    /// @notice Burn token is used in Run or Die mechanic
    /// @dev Liquidation contract will be have operator right to burn tokens
    function burnFrom(uint tokenId) external onlyOperator {
        _burn(tokenId, false);
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

    /// @notice Internal function used in signature checking
    function hashArguments(
        uint tokenId, bytes calldata genome)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(tokenId, genome));
    }

    /// @notice Internal function used in signature checking
    function getSigner(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(tokenId, genome);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    /// @notice Internal function used in signature checking
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

    /// @notice Setups roach genome and give birth to it
    /// @dev Checks passed genome using serve generated signature
    function reveal(uint tokenId, bytes calldata genome, uint tokenSeed, uint8 sigV, bytes32 sigR, bytes32 sigS) external {
        require(ownerOf(tokenId) == msg.sender, "Wrong egg owner");
        require(isValidSignature(tokenId, genome, sigV, sigR, sigS), "Wrong signature");
        _reveal(tokenId, genome);
    }

    /// @notice Setups roach genome and give birth to it
    /// @dev Can be called only by authorized operator (another contract or backend)
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

    // TODO: optimize
    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i = 0; i < n; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    /// @notice Sets new Metadata implementation
    function setMetadataContract(IMetadata newContract) external onlyOwner {
        _setMetadataContract(newContract);
    }

    function _setMetadataContract(IMetadata newContract) internal {
        metadataContract = newContract;
        emit MetadataContractChanged(newContract);
    }

    /// @notice Returns token metadata URI according to IERC721Metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        return metadataContract.tokenURI(tokenId);
    }

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory) {
        return metadataContract.contractURI();
    }

}
