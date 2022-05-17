// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../Reveal.sol";

contract RevealTest is Reveal {

    constructor(IRoachNFT _roachContract)
        Reveal(_roachContract)
    {
    }

    /// @notice Signature checking stub for tests
    function isValidSignature(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        override
        returns (bool)
    {
        return true;
    }

}
