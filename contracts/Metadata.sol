// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/utils/Strings.sol";
import "../interfaces/IMetadata.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Can be changed in future to support new features
 */
contract Metadata is IMetadata {
    using Strings for uint256;
    string public baseURI;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    /**
    * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

}
