// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

/// @title ERC-721 Non-Fungible Token Standard, metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IMetadata {

    /// @notice Returns token metadata URI according to IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory);

    /// @notice Returns roach name by index
    function getName(uint256 tokenId) external view returns (string memory);

}
