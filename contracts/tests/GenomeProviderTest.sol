// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenomeProviderPolygon.sol";

contract GenomeProviderTest is GenomeProviderPolygon {

    constructor(uint256 _secret_seed_hash) GenomeProviderPolygon(_secret_seed_hash) {
    }

    function getTraitWeightSum(uint traitId) external view returns (uint32) {
        return traits[traitId].sum;
    }

    function getTraitSetupData(uint traitId) external view returns (uint8[] memory) {
        return traits[traitId].traitData;
    }

    function getTraitSetupSlots(uint traitId) external view returns (uint8[] memory) {
        return traits[traitId].slots;
    }

    function getTraitWeight(uint traitId) external view returns (uint16[] memory) {
        return traits[traitId].weight;
    }

    function getTraitWeightMaxBonus(uint traitId) external view returns (uint16[] memory) {
        return traits[traitId].weightMaxBonus;
    }

    function getWeightedRandomTest(uint traitType, uint randomSeed, uint bonus) external view returns (uint) {
        (uint choise,) = getWeightedRandom(traitType, randomSeed, bonus);
        return choise;
    }

    function normalizeGenome(uint256 _randomness, uint8 _traitBonus) external view returns (bytes memory) {
        return _normalizeGenome(_randomness, _traitBonus);
    }

}
