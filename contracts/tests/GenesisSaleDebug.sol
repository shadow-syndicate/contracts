// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "../GenesisSale.sol";

contract GenesisSaleDebug is GenesisSale {

    constructor(
        IERC20 _moneyToken,
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
        GenesisSale(_moneyToken, _roachContract, stage1startTime, stage1durationSeconds, price, totalTokensOnSale)
    {
    }
    function setStage0() external onlyOperator {
        STAGE1_START = block.timestamp + 60*60;
        soldCount = 0;
    }

    function setStage1() external onlyOperator {
        STAGE1_START = block.timestamp;
        soldCount = 0;
    }

    function setStage2() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
        soldCount = 0;
    }

    function setStage3() external onlyOperator {
        STAGE1_START = block.timestamp - STAGE1_DURATION;
        soldCount = TOTAL_TOKENS_ON_SALE;
    }

}
