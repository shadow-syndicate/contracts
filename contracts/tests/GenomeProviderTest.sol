// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenomeProviderMock.sol";

contract GenomeProviderTest is GenomeProviderMock {

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
        return _calculateGenome(_randomness, _traitBonus);
    }

}
