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

    /**
    * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "https://meta.roachracingclub.com/roach/";
    }

}
