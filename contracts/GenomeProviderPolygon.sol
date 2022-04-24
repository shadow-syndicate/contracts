// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../interfaces/IRoachNFT.sol";
import "./Operators.sol";

contract GenomeProviderPolygon is Operators {

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

    uint256 public vrf_seed;
    uint256 public secret_seed_hash;

    constructor(uint256 _secret_seed_hash) {
        secret_seed_hash = _secret_seed_hash;
    }

    function getTokenSeed(uint token_id, uint trait_bonus, uint secret_seed, uint mint_block_hash)
        external view returns (uint token_seed)
    {
        return uint(keccak256(abi.encodePacked(token_id, trait_bonus, vrf_seed, secret_seed, mint_block_hash)));
    }

    function calculateGenome(uint256 token_seed, uint8 trait_bonus) external view returns (bytes memory genome) {
        genome = _normalizeGenome(token_seed, trait_bonus);
    }

    function requestVrfSeed() external onlyOwner {
        require(vrf_seed == 0, "Can't call twice");
        _requestRandomness();
    }

    // Stub, will be overriden in Chainlink version
    function _requestRandomness() internal virtual {
        uint256 randomness = uint(keccak256(abi.encodePacked(block.timestamp)));
        _onRandomnessArrived(randomness);
    }

    function _onRandomnessArrived(uint256 _randomness) internal {
        require(vrf_seed == 0, "Can't call twice");
        vrf_seed = _randomness;
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
