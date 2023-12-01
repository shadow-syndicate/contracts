// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenesisMint.sol";

contract GenesisMintDebug is GenesisMint {

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint totalTokensOnSale)
        GenesisMint(_roachContract, stage1startTime, stage1durationSeconds, totalTokensOnSale)
    {
    }

    function mintStage1noSig(
        uint desiredCount,
        uint limitForAccount,
        uint price
    )
        external payable
    {
        _mint(msg.sender, desiredCount, limitForAccount, price);
    }

    function setStage0(uint duration) external onlyOperator {
        SALE_START = block.timestamp + duration;
    }

    function setStage1(uint duration) external onlyOperator {
        SALE_START = block.timestamp;
        SALE_DURATION = duration;
    }

    function setStage2() external onlyOperator {
        SALE_START = block.timestamp - SALE_DURATION;
    }

    function setStage3() external onlyOperator {
        SALE_START = block.timestamp - SALE_DURATION;
    }

}
