// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenomeProvider.sol";

contract GenomeProviderTest is GenomeProvider {

    constructor(IRoachNFT _roachContract) GenomeProvider(_roachContract) {
    }

    function getTraitWeightSum(uint traitId) external view returns (uint) {
        return traitWeight[traitId].sum;
    }

    function getTraitWeight(uint traitId) external view returns (uint[] memory) {
        return traitWeight[traitId].weight;
    }

    function getTraitWeightMaxBonus(uint traitId) external view returns (uint[] memory) {
        return traitWeight[traitId].weightMaxBonus;
    }

    function getWeightedRandomTest(uint traitType, uint randomSeed, uint bonus) external view returns (uint) {
        (uint choise,) = getWeightedRandom(traitType, randomSeed, bonus);
        return choise;
    }

    function normalizeGenome(uint256 _randomness, uint32 _traitBonus) external view returns (bytes memory) {
        return _normalizeGenome(_randomness, _traitBonus);
    }

}
