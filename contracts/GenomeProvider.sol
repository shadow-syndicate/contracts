// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../interfaces/IGenomeProvider.sol";
import "../interfaces/IRoachNFT.sol";

contract GenomeProvider is IGenomeProvider {

    IRoachNFT public roachContract;

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function requestGenome(uint tokenId, uint32 traitBonus) external {
        require(msg.sender == address(roachContract), 'Access denied');
        _requestGenome(tokenId, traitBonus);
    }

    function _requestGenome(uint256 _tokenId, uint32 _traitBonus) internal virtual {
        uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        _onGenomeArrived(_tokenId, randomSeed, _traitBonus);
    }

    function _onGenomeArrived(uint256 _tokenId, uint256 _randomness, uint32 _traitBonus) internal {
        bytes memory genome = _normalizeGenome(_randomness, _traitBonus);
        roachContract.setGenome(_tokenId, genome);
    }

    function _normalizeGenome(uint256 _randomness, uint32 _traitBonus) internal returns (bytes memory) {
        bytes memory result = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            result[i] = bytes1(uint8(_randomness & 0xFF));
            _randomness >>= 8;
        }
        return result; // TODO: fix genome * traitBonus
    }

}
