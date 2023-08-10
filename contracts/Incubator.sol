// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "./Operators.sol";

contract Incubator is Operators {

    event Created(address user, uint index);
    event Initiated(address user, uint index, uint parent1, uint parent2);
    event Egg(address user, uint index);
    event Available(address user, uint index);
    event Roll(address user, uint index);

    function buySlot() external {
        // emit Created(msg.sender, index);
    }

    function unlockSlot(uint sigv) external {
        // emit Created(msg.sender, index);
    }

    function init(uint index, int parent1, int parent2) external {
        emit Initiated(msg.sender, index);
    }

    function start(uint index) external {
        emit Egg(msg.sender, index);
    }

    function roll(uint index) external {

    }

    function cancel(uint index) external {
        emit Available(msg.sender, index);
    }

    function reveal(uint index) external {
        emit Available(msg.sender, index);
    }

    function speedup(uint index) external {
        emit Available(msg.sender, index);
    }
}
