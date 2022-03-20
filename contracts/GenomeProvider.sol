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

    struct TraitWeight {
        uint sum;
        uint[] weight;
        uint[] weightMaxBonus;
    }

    mapping(uint => TraitWeight) public traits; // slot -> array of trait weight

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function requestGenome(uint tokenId, uint32 traitBonus) external {
        require(msg.sender == address(roachContract), 'Access denied');
        _requestGenome(tokenId, traitBonus);
    }

    function _onGenomeArrived(uint256 _tokenId, uint256 _randomness, uint32 _traitBonus) internal {
        bytes memory genome = _normalizeGenome(_randomness, _traitBonus);
        roachContract.setGenome(_tokenId, genome);
    }

    function _requestGenome(uint256 _tokenId, uint32 _traitBonus) internal virtual {
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        _onGenomeArrived(_tokenId, randomSeed, _traitBonus);
    }

    function setTraitWeight(uint traitType, uint[] calldata _traitWeight, uint[] calldata _traitWeightMaxBonus)
        external onlyOperator
    {
        require(_traitWeight.length < 0xff, 'trait variant count');
        require(_traitWeight.length == _traitWeightMaxBonus.length, 'weight length mismatch');
        uint sum = 0;
        for (uint i = 0; i < _traitWeight.length; i++) {
            sum += _traitWeight[i];
        }
        traits[traitType] = TraitWeight(sum, _traitWeight, _traitWeightMaxBonus);
    }

    function getWeightedRandom(uint traitType, uint randomSeed, uint bonus)
        internal view
        returns (uint choice, uint newRandomSeed)
    {
        TraitWeight storage w = traits[traitType];
        uint div = w.sum * MAX_BONUS;
        uint r = randomSeed % div;
        uint i = 0;
        uint acc = 0;
        while (true) {
            acc += w.weight[i] * (MAX_BONUS - bonus) + (w.weightMaxBonus[i] * bonus);
            if (acc > r) {
                choice = i;
                newRandomSeed = randomSeed / div;
                break;
            }
            i++;
        }
    }

    function _normalizeGenome(uint256 _randomness, uint32 _traitBonus) internal view returns (bytes memory) {
        bytes memory result = new bytes(32);
        result[0] = 0; // version
        for (uint i = 1; i <= TRAIT_COUNT; i++) {
            uint trait;
            (trait, _randomness) = getWeightedRandom(i, _randomness, _traitBonus);
            result[i] = bytes1(uint8(trait));
        }
        for (uint i = TRAIT_COUNT + 1; i < 32; i++) {
            result[i] = bytes1(uint8(_randomness & 0xFF));
            _randomness >>= 8;
        }
        return result;
    }

}
