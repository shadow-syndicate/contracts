// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;
import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract GeneMixer is Operators {
    IRoachNFT public roachNtf;

    constructor (IRoachNFT _roachNtf) {
        roachNtf = _roachNtf;
    }

    function calculateGenome(uint40 parent0, uint40 parent1, uint seed) external returns (
        bytes memory genome,
        uint40 generation,
        uint16 resistance
    ){
        bytes memory genome0;
        uint40 generation0;
        uint16 resistance0;
        (genome0, generation0, resistance0) = roachNtf.getRoachShort(parent0);
        bytes memory genome1;
        uint40 generation1;
        uint16 resistance1;
        (genome1, generation1, resistance1) = roachNtf.getRoachShort(parent1);

        // TODO: add correct formulas
        genome = genome1;
        generation = generation0 > generation1 ? generation0 + 1 : generation1 + 1;
        resistance = (resistance0 + resistance1)/2;
    }

    function canBreed(uint40 parent0, uint40 parent1) external returns (bool) {
        return parent0 != parent1;
    }

}
