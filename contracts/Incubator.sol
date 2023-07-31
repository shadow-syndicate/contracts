// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "./Operators.sol";

contract Incubator is Operators {

    event Created(address account, uint index);
    event Initiated(address account, uint index);
    event Egg(address account, uint index);
    event Available(address account, uint index);
    event Roll(address account, uint index);

    function buySlot() external {
        // emit Created(msg.sender, index);
    }

    function unlockSlot(uint sigv) external {
        // emit Created(msg.sender, index);
    }

    function init(uint index, uint roachId1, uint roachId2) external {
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
