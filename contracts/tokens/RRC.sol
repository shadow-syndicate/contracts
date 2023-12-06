// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol";
import "../Operators.sol";

contract RRC is ERC20, Operators {

    uint constant MAX_SUPPLY = 1000000000 ether;

    constructor()
        ERC20("Roach Racing Club", "RRC")
    {
    }

    function mint(address to, uint256 amount) external onlyOperator {
        require(amount <= MAX_SUPPLY, "Max supply amount exceed!");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply amount exceed!");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
