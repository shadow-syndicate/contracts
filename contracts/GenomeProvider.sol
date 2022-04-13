// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../interfaces/IGenomeProvider.sol";
import "../interfaces/IRoachNFT.sol";
import "./Operators.sol";

contract GenomeProvider is IGenomeProvider, Operators {

    IRoachNFT public roachContract;
    uint constant TRAIT_COUNT = 6;
    uint constant MAX_BONUS = 25;

    struct TraitConfig {
        uint sum;
        uint[] slots;
        // data format: trait1, color1a, color1b, trait2, color2a, color2b, ...
        uint[] traitData;
        uint[] weight;
        uint[] weightMaxBonus;
    }

    mapping(uint => TraitConfig) public traits; // slot -> array of trait weight
    mapping (uint => uint256) public tokenIdToRandomness;
    mapping (uint => uint8) public tokenIdToTraitBonus;

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function isReadyForReveal(uint tokenId) external view returns (bool) {
        return tokenIdToRandomness[tokenId] != 0;
    }

    function requestGenome(uint tokenId, uint8 traitBonus) external {
        require(msg.sender == address(roachContract), 'Access denied');
        tokenIdToTraitBonus[tokenId] = traitBonus;
        _requestRandomness(tokenId);
    }

    function _onRandomnessArrived(uint256 _tokenId, uint256 _randomness) internal {
        tokenIdToRandomness[_tokenId] = _randomness;
    }

    function reveal(uint tokenId) external {
        require(msg.sender == address(roachContract), 'Access denied');
        uint256 randomness = tokenIdToRandomness[tokenId];
        uint8 traitBonus = tokenIdToTraitBonus[tokenId];
        delete tokenIdToRandomness[tokenId];
        delete tokenIdToTraitBonus[tokenId];
        bytes memory genome = _normalizeGenome(randomness, traitBonus);
        roachContract.setGenome(tokenId, genome);
    }

    // Stub, will be overriden in Chainlink version
    function _requestRandomness(uint256 _tokenId) internal virtual {
        uint256 randomness = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId)));
        _onRandomnessArrived(_tokenId, randomness);
    }

    function setTraitConfig(
        uint traitIndex,
        uint[] calldata _slots,
        uint[] calldata _traitData,
        uint[] calldata _weight,
        uint[] calldata _weightMaxBonus
    )
        external onlyOperator
    {
        require(_weight.length == _weightMaxBonus.length, 'weight length mismatch');
        require(_slots.length * _weight.length == _traitData.length, '_traitData length mismatch');

        uint sum = 0;
        for (uint i = 0; i < _weight.length; i++) {
            sum += _weight[i];
        }
        traits[traitIndex] = TraitConfig(sum, _slots, _traitData, _weight, _weightMaxBonus);
    }

    function getWeightedRandom(uint traitType, uint randomSeed, uint bonus)
        internal view
        returns (uint choice, uint newRandomSeed)
    {
        TraitConfig storage config = traits[traitType];
        uint div = config.sum * MAX_BONUS;
        uint r = randomSeed % div;
        uint i = 0;
        uint acc = 0;
        while (true) {
            acc += config.weight[i] * (MAX_BONUS - bonus) + (config.weightMaxBonus[i] * bonus);
            if (acc > r) {
                choice = i;
                newRandomSeed = randomSeed / div;
                break;
            }
            i++;
        }
    }

    function _normalizeGenome(uint256 _randomness, uint8 _traitBonus) internal view returns (bytes memory) {

        bytes memory result = new bytes(32);
        result[0] = 0; // version
        for (uint i = 1; i <= TRAIT_COUNT; i++) {
            uint trait;
            (trait, _randomness) = getWeightedRandom(i, _randomness, _traitBonus);
            TraitConfig storage config = traits[i];
            for (uint j = 0; j < config.slots.length; j++) {
                result[config.slots[j]] = bytes1(uint8(config.traitData[trait * config.slots.length + j]));
            }
        }

        TraitConfig storage lastConfig = traits[TRAIT_COUNT];
        uint maxSlot = lastConfig.slots[lastConfig.slots.length - 1];
        for (uint i = maxSlot + 1; i < 32; i++) {
            result[i] = bytes1(uint8(_randomness & 0xFF));
            _randomness >>= 8;
        }
        return result;
    }
}
