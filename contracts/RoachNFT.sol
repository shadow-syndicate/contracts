// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC721/ERC721.sol";

contract RoachNFT is ERC721 {

    constructor() ERC721('Roach Racing Club', 'ROACH') {
    }
    
}
