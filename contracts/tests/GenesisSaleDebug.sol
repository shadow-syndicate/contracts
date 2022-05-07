// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenesisSale.sol";

contract GenesisSaleDebug is GenesisSale {

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
        GenesisSale(_roachContract, stage1startTime, stage1durationSeconds, price, totalTokensOnSale)
    {
    }

    function mintStage1noSig(
        uint wantCount,
        uint limitForAccount,
        uint8 traitBonus,
        string calldata syndicate
    )
        external payable
    {
        _mintStage1(msg.sender, wantCount, limitForAccount, syndicate, traitBonus);
    }

    function setStage0(uint duration) external onlyOperator {
        STAGE1_START = block.timestamp + duration;
    }

    function setStage1(uint duration) external onlyOperator {
        STAGE1_START = block.timestamp;
        STAGE1_DURATION = duration;
    }

    function setStage2() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
    }

    function setStage3() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
    }

}
