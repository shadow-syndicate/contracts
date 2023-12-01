// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../Operators.sol";
import "../../interfaces/IRoachNFT.sol";
import "./Reveal.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev For deploy and manual tests
contract RevealDebug is Reveal {

    constructor(IRoachNFT _roachContract) Reveal(_roachContract) {
    }

    function _requestReveal(uint tokenId) internal override {
        uint seed = uint(keccak256(abi.encodePacked(blockhash(block.number - 1)))) ^ tokenId;
        revealCallback(tokenId, seed);
    }

    function claim(uint count) external {
        require(count <= 10, 'Count > 10');
        roachContract.mintGen0(msg.sender, count);
        uint lastId = roachContract.lastRoachId();
        for (uint i = lastId - count + 1; i <= lastId; i++) {
            _requestReveal(i);
        }
    }
}
