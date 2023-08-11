// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;
import "./Operators.sol";

contract Config is Operators {
    // returns mutagen, rrc
    function getBuySlotPrice(address user) external pure
        returns (uint[2] memory tokenValues)
    {
        tokenValues[0] = 0;
        tokenValues[1] = 1000;
    }

    function getInitPrice(uint40 parent0, uint40 parent1) external pure
        returns (uint[2] memory tokenValues)
    {
        tokenValues[0] = 100;
        tokenValues[1] = 0;
    }

    function getStartPrice(uint40 parent0, uint40 parent1) external pure
        returns (uint[2] memory tokenValues)
    {
        tokenValues[0] = 10;
        tokenValues[1] = 10;
    }

    function getRollPrice(uint rollNumber) external pure
        returns (uint[2] memory tokenValues)
    {
        tokenValues[0] = 0;
        tokenValues[1] = rollNumber;
    }

    function getSpeedupPrice(uint leftTimeSeconds) external pure
        returns (uint[2] memory tokenValues)
    {
        tokenValues[0] = 0;
        tokenValues[1] = leftTimeSeconds;
    }

    function isGoodBreedCount(uint breedCount) external pure
        returns (bool)
    {
        return breedCount < 7;
    }

    function getRevealCooldown() external pure
        returns (uint)
    {
        return 60;
    }

}
