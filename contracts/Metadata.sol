// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/utils/Strings.sol";
import "../interfaces/IMetadata.sol";

/// @title ERC-721 Non-Fungible Token Standard, metadata extension
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///      Can be changed in future to support new features
contract Metadata is IMetadata {
    using Strings for uint256;
    string public baseURI;
    string public contractUri;

    constructor(string memory _baseURI, string memory _contractURI) {
        baseURI = _baseURI;
        contractUri = _contractURI;
    }

    /// @notice Returns token metadata URI according to IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /// @notice Returns roach name by index
    /// @dev In future realizations there will a possibility to change name
    function getName(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("Roach ", tokenId.toString()));
    }

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory) {
        return contractUri;
    }

}
