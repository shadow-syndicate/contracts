import "./GenesisMint2.sol";// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

contract GenesisMint2Debug is GenesisMint2 {

    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken,
        uint stage1startTime)
        GenesisMint2(_roachContract, _traxToken, stage1startTime)
    {
        MINT_START = stage1startTime;
    }

    function _requestRandomForMint(address account) override internal {
        uint seed = uint(keccak256(abi.encodePacked(blockhash(block.number - 1)))) ^ roachContract.lastRoachId();
        _randomCallback(account, seed);
    }

    function setStage(uint mintStartTime, uint mintDuration, uint totalTolkensToMint) external onlyOperator {
        MINT_START = mintStartTime;
        MINT_DURATION = mintDuration;
        TOTAL_TOKENS_TO_MINT = totalTolkensToMint;
    }

    function setProbability(uint baseProbability) external onlyOperator {
        BASE_PROBABILITY = baseProbability;
    }

    function mintWhitelistedNoSig(uint limitForAccount)
        external payable
    {
        _mint(msg.sender, limitForAccount);
    }
}
