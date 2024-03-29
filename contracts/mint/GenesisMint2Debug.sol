// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./GenesisMint2.sol";

contract GenesisMint2Debug is GenesisMint2 {

    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken,
        uint stage1startTime)
        GenesisMint2(_roachContract, _traxToken, stage1startTime)
    {
        MINT_START = stage1startTime;
    }

    function _requestRandomForMint(address account) override internal returns (uint256 requestId) {
        uint seed = uint(keccak256(abi.encodePacked(blockhash(block.number - 1)))) ^ roachContract.lastRoachId();
        requestId = roachContract.lastRoachId();
        _randomCallback(account, seed, requestId);
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
