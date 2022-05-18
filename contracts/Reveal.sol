// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

/// @title Roach NFT genome reveal contract
/// @author Shadow Syndicate / Andrey Pelipenko (kindex@kindex.lv)
/// @dev Reveal genome using server generated signature
///      Genome generation is described in GenomeProviderPolygon.sol
contract Reveal is Operators {

    address public signerAddress;
    IRoachNFT public roachContract;

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
        signerAddress = msg.sender;
    }

    /// @notice Internal function used in signature checking
    function hashArguments(
        uint tokenId, bytes calldata genome)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(tokenId, genome));
    }

    /// @notice Internal function used in signature checking
    function getSigner(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(tokenId, genome);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    /// @notice Internal function used in signature checking
    function isValidSignature(
        uint tokenId, bytes calldata genome,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        virtual
        returns (bool)
    {
        return getSigner(tokenId, genome, sigV, sigR, sigS) == signerAddress;
    }

    /// @notice Setups roach genome and give birth to it.
    /// @dev    Checks passed genome using generated signature by server.
    function reveal(uint tokenId, bytes calldata genome, uint tokenSeed, uint8 sigV, bytes32 sigR, bytes32 sigS) external {
        require(roachContract.ownerOf(tokenId) == msg.sender, "Wrong egg owner");
        require(isValidSignature(tokenId, genome, sigV, sigR, sigS), "Wrong signature");
        roachContract.revealOperator(tokenId, genome);
    }

    /// @notice Changes secret key that is used for signature generation
    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

}
