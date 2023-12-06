// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./IRoach.sol";
import "../contracts/ERC721A/IERC721A.sol";
import "./IERC5192.sol";

/// @title Roach Racing Club NFT registry interface
interface IRoachNFT is IRoach, IERC721A, IERC5192 {
}
