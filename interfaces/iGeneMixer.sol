// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

interface IGeneMixer {

    function calculateGenome(uint40 parent0, uint40 parent1, uint seed) external returns (
        bytes memory genome,
        uint40 generation,
        uint16 resistance
    );

    function canBreed(uint40 parent0, uint40 parent1) external returns (bool);
}
