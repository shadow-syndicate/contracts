// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
/*
                                                                   ..::--------::..
                                                               .:--------------------::
                                                            :----------------------------:
                                                         .:---------------------------------.
                                                        :-------------------------------------
                                                      .----------------------------------------:
                                                     :------------------------------------------:
                                                    :--===----------------------------------===--:
                                                   .--+@@@@%%#+=----------------------=+*#%@@@@+--:
                                                   ---@@@@@@@@@@@#+----------------+#@@@@@@@@@@@=--
                                                  :--+@@@@@@@@@@@@@@#+----------=#@@@@@@@@@@@@@@*--:
                                                  ---#@@@@@@@@@@@@@@@@%+------=%@@@@@@@@@@@@@@@@%---
                                                  -----==+*%@@@@@@@@@@@@%=--=#@@@@@@@@@@@@%*++=-----
                                                  -----------=*@@@@@@@@@@@*+@@@@@@@@@@@#+-----------
                                                  :-------------+%@@@@@@@@@@@@@@@@@@%+-------------:
                                                   ---------------*@@@@@@@@@@@@@@@@*---------------
                                                   :---------------=@@@@@@@@@@@@@@+---------------:
                                                    :---------------=@@@@@@@@@@@@=----------------
                                                     :---------------+@@@@@@@@@@*---------------:
                                                      :---------------%@@@@@@@@@---------------:
                                                        --------------#@@@@@@@@%--------------.
                                                         .------------#@@@@@@@@#------------.
                                                            :---------*@@@@@@@@#---------:.
                                                               :----------------------:.
                                                                     ..::--------:::.



███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗    ███████╗██╗   ██╗███╗   ██╗██████╗ ██╗ ██████╗ █████╗ ████████╗███████╗    ██╗███╗   ██╗ ██████╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║    ██╔════╝╚██╗ ██╔╝████╗  ██║██╔══██╗██║██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ██║████╗  ██║██╔════╝
███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║    ███████╗ ╚████╔╝ ██╔██╗ ██║██║  ██║██║██║     ███████║   ██║   █████╗      ██║██╔██╗ ██║██║
╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║    ╚════██║  ╚██╔╝  ██║╚██╗██║██║  ██║██║██║     ██╔══██║   ██║   ██╔══╝      ██║██║╚██╗██║██║
███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝    ███████║   ██║   ██║ ╚████║██████╔╝██║╚██████╗██║  ██║   ██║   ███████╗    ██║██║ ╚████║╚██████╗██╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝

*/

pragma solidity ^0.8.23;

import "./ERC721A/ERC721A.sol";
import "./Operators.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/IERC4906.sol";
import "../interfaces/IERC5192.sol";

/// @title Roach Racing Club NFT registry
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Stores NFT ownership and metadata like genome and parents.
///      Uses ERC-721A implementation to optimize gas consumptions during batch mints.
contract RoachNFT is ERC721A, Operators, IRoach, IERC4906, IERC5192 {

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
        uint16 breedCount;
        // Whether the token has been locked.
        bool locked;
    }

    mapping(uint => Roach) public roach;
    uint16 public constant GEN0_RESISTANCE = 10000; // 100%
    uint16 public MAX_BREED_COUNT = 7;
    IMetadata public metadataContract;
    mapping(address => bool) public whitelistedTransferToWhenLocked;
    mapping(address => bool) public whitelistedTransferFromWhenLocked;

    event Mint(address indexed account, uint indexed tokenId);
    event Reveal(address indexed owner, uint indexed tokenId);
    event GenomeChanged(uint indexed tokenId, bytes genome);
    event Birth(address indexed owner, uint indexed tokenId, bytes genome, uint40[2] parents, uint40 generation, uint16 resistance);
    event BreedCountChanged(uint indexed tokenId, uint breedCount);
    event MetadataContractChanged(IMetadata metadataContract);

    // TODO: matadata batch update

    constructor(IMetadata _metadataContract)
        ERC721A('RCH', 'R')
    {
        _setMetadataContract(_metadataContract);
        setTransferToWhenLockedWhitelist(address(0x0), true);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /// @dev Token numeration starts from 1 (genesis collection id 1..10k)
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    /// @notice Returns contract level metadata for roach
    /// @return genome       Array of genes in secret format
    /// @return parents      Array of 2 parent roach id
    /// @return creationTime UNIX time when egg was minted
    /// @return revealTime   UNIX time when egg was revealed to roach
    /// @return generation   Gen0, Gen1, etc
    /// @return resistance   Resistance percentage (1234 = 12.34%)
    /// @return breedCount   number of breed tries
    /// @return name         Roach name
    function getRoach(uint roachId) external view
        returns (
            bytes memory genome,
            uint40[2] memory parents,
            uint40 creationTime,
            uint40 revealTime,
            uint40 generation,
            uint16 resistance,
            uint16 breedCount,
            string memory name,
            address owner)
    {
        require(_exists(roachId), "query for nonexistent token");
        Roach storage r = roach[roachId];
        genome = r.genome;
        parents = r.parents;
        creationTime = r.creationTime;
        revealTime = r.revealTime;
        generation = r.generation;
        resistance = r.generation == 0 ? GEN0_RESISTANCE : r.resistance;
        breedCount = r.breedCount;
        name = metadataContract.getName(roachId);
        owner = ownerOf(roachId);
    }

    function getBreedCount(uint roachId) external view returns (uint16 breedCount) {
        require(_exists(roachId), "query for nonexistent token");
        Roach storage r = roach[roachId];
        breedCount = r.breedCount;
    }

    /// @notice Returns contract level metadata for roach
    /// @return genome       Array of genes in secret format
    /// @return generation   Gen0, Gen1, etc
    /// @return resistance   Resistance percentage (1234 = 12.34%)
    function getRoachShort(uint roachId) external view
        returns (
            bytes memory genome,
            uint40 generation,
            uint16 resistance)
    {
        require(_exists(roachId), "query for nonexistent token");
        Roach storage r = roach[roachId];
        genome = r.genome;
        generation = r.generation;
        resistance = r.generation == 0 ? GEN0_RESISTANCE : r.resistance;
    }

    function getRoachBatch(uint[] calldata roachIds) external view
        returns (
            Roach[] memory roachData,
            string[] memory name,
            address[] memory owner)
    {
        roachData = new Roach[](roachIds.length);
        name = new string[](roachIds.length);
        owner = new address[](roachIds.length);

        for (uint i = 0; i < roachIds.length; i++) {
            uint roachId = roachIds[i];
            require(_exists(roachId), "query for nonexistent token");
            roachData[i] = roach[roachId];
            name[i] = metadataContract.getName(roachId);
            owner[i] = ownerOf(roachId);
        }
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
        roach[_currentIndex] = Roach(genome, parents, uint40(block.timestamp), 0, generation, resistance, 0, false);
        emit Birth(to, _currentIndex, genome, parents, generation, resistance);
        _mint(to, 1);
    }

    /// @notice Mints new token with autoincremented index
    /// @dev Only for gen0
    /// @dev Can be called only by authorized operator (GenesisMint contract)
    function mintGen0(address to, uint count) external onlyOperator {
        uint tokenId = _currentIndex;
        _mint(to, count);
        for (uint i = 0; i < count; i++) {
            // do not save Roach struct to mapping for Gen0 because all data is default
            emit Mint(to, tokenId + i);
        }
    }

    /// @notice Cancels burn for bridge between chains
    /// @dev NFT Bridge burns token when transferring to another chain.
    /// @dev When NFT Bridge returns token back to current contract revive is called.
    /// @dev Can be called only by authorized operator (bridge contract)
    function revive(
        address to,
        uint tokenId
    ) external onlyOperator {
        require(_burned(tokenId), 'not burned');
        _revive(to, tokenId);
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

    function incBreedCount(uint tokenId) external onlyOperator {
        roach[tokenId].breedCount++;
        require(roach[tokenId].breedCount <= MAX_BREED_COUNT, "Breed count limit");
        emit BreedCountChanged(tokenId, roach[tokenId].breedCount);
    }

    function setMaxBreedCount(uint16 newMaxBreedCount) external onlyOwner {
        MAX_BREED_COUNT = newMaxBreedCount;
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
        return !_isRevealed(r);
    }

    /// @notice Setups roach genome and give birth to it.
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
        emit Birth(ownerOf(tokenId), tokenId, genome, roach[tokenId].parents, roach[tokenId].generation, roach[tokenId].resistance);
        _setGenome(tokenId, genome);
        if (!_locked(tokenId)) {
            _lock(tokenId);
        }
    }

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list.
    ///      Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId)
    {
        uint count = 0;
        for (uint i = _startTokenId(); i <= _lastRoachId(); ++i) {
            if (_exists(i) && ownerOf(i) == owner) {
                if (count == index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert("owner index out of bounds");
    }

    /// @dev Returns all tokens owned by `owner`.
    function getUsersTokens(address owner) external view returns (uint256[] memory) {
        uint256 n = balanceOf(owner);

        uint256[] memory result = new uint256[](n);
        uint count = 0;
        for (uint i = _startTokenId(); i <= _lastRoachId(); ++i) {
            if (_exists(i) && ownerOf(i) == owner) {
                result[count] = i;
                count++;
            }
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
        require(_exists(tokenId), "RoachNFT: URI query for nonexistent token");

        return metadataContract.tokenURI(tokenId);
    }

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory) {
        return metadataContract.contractURI();
    }

    function locked(uint tokenId) external view returns (bool) {
        require(_exists(tokenId), "RoachNFT: nonexistent token");
        return _locked(tokenId);
    }

    function _locked(uint tokenId) internal view returns (bool) {
        return roach[tokenId].locked;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function lockOperator(uint tokenId) external onlyOperator {
        _lock(tokenId);
    }

    function _lock(uint tokenId) internal {
        require(!_locked(tokenId), 'already locked');
        roach[tokenId].locked = true;
        emit Locked(tokenId);
    }

    function unlockOperator(uint tokenId) external onlyOperator {
        _unlock(tokenId);
    }

    function _unlock(uint tokenId) internal {
        require(_locked(tokenId), 'already unlocked');
        roach[tokenId].locked = false;
        emit Unlocked(tokenId);
    }

    function setTransferToWhenLockedWhitelist(address account, bool status) public onlyOperator {
        whitelistedTransferToWhenLocked[account] = status;
    }

    function setTransferFromWhenLockedWhitelist(address account, bool status) public onlyOperator {
        whitelistedTransferFromWhenLocked[account] = status;
    }

    function canTransferToWhenLocked(address account) view public returns (bool) {
        return whitelistedTransferToWhenLocked[account];
    }

    function canTransferFromWhenLocked(address account) view public returns (bool) {
        return whitelistedTransferFromWhenLocked[account];
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (canTransferToWhenLocked(to) || canTransferFromWhenLocked(from)) {
            return;
        }
        for (uint i = 0; i < quantity; i++) {
            require(!_locked(startTokenId + i), 'Locked');
        }
    }

    function metadataUpdate(uint256 _tokenId) external onlyOperator {
        emit MetadataUpdate(_tokenId);
    }

    function batchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId) external onlyOperator {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

}
/*
.................................,,:::,...........
..............................,:;;;:::;;;,........
...............,,,,,.........:;;,......,;+:.......
.............:::,,,::,.....,+;,..........:*;......
...........,;:.......,:,..,+:.............:*:.....
..........:;,..........:,.+:...............*+.....
.........,+,..........,,:;+,,,.............;*,....
.........+:.......,:+?SS####SS%*;,.........;*:....
........:+.....,;?S##############S?:.......;*,....
........;+....;?###############%??##+......+*,....
........:+...,%SS?;?#########@@S?++S#:....,+;.....
........,+:..,%S%*,*#####SSSSSS%*;,%S,............
.........;;,..;SS%S#####SSSS%%%?+:*%;.............
..........,....:%########SSS%%?*?%?,..............
.............,,,.+S##@#?+;;*%%SS%;................
.........,,.,+++;:+%##?+*+:,?##S+;:,..............
....,,;+*SS*??***++?S#S?*+:,%S%%%%%?+:,......,....
,:;**???*?#@##S?***++*%%*;,:%%%%**?%%?;,,.,;?%?%??
????*+;:,,*####S%%?*+;:;;,,+#S%%%?*?%??+;*%S?*%SSS
*+;:,....,%@S####SS%?*+:::*S@#%%%%????%%S%*;::,,,:
.........+@@S%S####S#@%?%%SS#@SS%%%%SS%*++;,......
........,%@@S%%S#@##@#%%%%%%S@##SSS%*+*?%?;,......
........:#@@%%%%%S@S##%%%%%%%#@##?++**%%S%+:......
........+@@#%SS%%%SSS?S%%%%%%S@SS?????%?S%*;,.....
........?@@@%%%%%%%%%%%%%%%%%%%%%%??**?%#%%;,.....
*/
