// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol";
import "../Operators.sol";

contract Mutagen is ERC20, Operators {

    constructor()
        ERC20("Mutagen", "MTGN")
    {
    }

    function mint(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
