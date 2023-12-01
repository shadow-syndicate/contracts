// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../Operators.sol";
import "../../interfaces/IRoachNFT.sol";
import "./RevealDebug.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev For unit tests
contract RevealTest is RevealDebug {

    constructor(IRoachNFT _roachContract) RevealDebug(_roachContract) {
    }

    function _withdrawGenome(uint seed) internal override returns (bytes memory genome) {
        return "AB";
    }
}
