// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenesisMint2ChainLink.sol";

contract GenesisMint2ChainlinkDebug is GenesisMint2Chainlink {

    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken,
        uint stage1startTime,
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint64 _subscriptionId)
        GenesisMint2Chainlink(_roachContract, _traxToken, stage1startTime, _vrfCoordinator, _chainLinkKeyHash, _subscriptionId)
    {
        MINT_START = stage1startTime;
    }

    function setStage(uint mintStartTime, uint mintDuration, uint totalTolkensToMint) external onlyOperator {
        MINT_START = mintStartTime;
        MINT_DURATION = mintDuration;
        TOTAL_TOKENS_TO_MINT = totalTolkensToMint;
    }

    function setProbability(uint baseProbability) external onlyOperator {
        BASE_PROBABILITY = baseProbability;
    }

    function mintWhitelistNoSig(uint limitForAccount)
        external payable
    {
        _mint(msg.sender, limitForAccount);
    }
}
