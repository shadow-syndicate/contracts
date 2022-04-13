// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/ERC20.sol";

contract TokenMock is ERC20 {
    constructor(string memory name_,
        string memory symbol_) ERC20(name_, symbol_)  {
        _mint(msg.sender, 1000e18);
    }

    function mint(address target, uint amount) external {
        _mint(target, amount);
    }
}
