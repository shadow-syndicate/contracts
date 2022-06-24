// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenomeProviderPolygon.sol";

contract GenomeProviderMock is GenomeProviderPolygon {

    /// @dev Stub function for filling random in tests
    function _requestRandomness(uint tokenId) internal override {
        uint256 randomness = uint(keccak256(abi.encodePacked(block.timestamp)));
        _onRandomnessArrived(tokenId, randomness);
    }

}
