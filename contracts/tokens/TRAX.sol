// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "./NonTransferrableToken.sol";

contract TRAX is NonTransferrableToken {

    constructor()
        ERC20("TRAX points", "TRAX")
    {
    }

}
