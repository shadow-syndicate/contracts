// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.10;

import "../interfaces/IRoachNFT.sol";
import "./Operators.sol";

contract Unlock is Operators {
    IRoachNFT public roachContract;

    constructor(IRoachNFT _roachContract) {
        roachContract = _roachContract;
    }

    function unlock(uint tokenId) external payable {
        require(roachContract.ownerOf(tokenId) == msg.sender, 'Wrong owner');
        // TODO: check payment
        roachContract.unlock(tokenId);
    }
}
