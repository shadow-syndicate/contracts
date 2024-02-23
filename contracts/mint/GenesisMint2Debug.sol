import "./GenesisMint2.sol";// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

contract GenesisMint2Debug is GenesisMint2 {

    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken)
        GenesisMint2(_roachContract, _traxToken)
    {
    }

    function _requestRandomForMint(address account) override internal {
        uint seed = uint(keccak256(abi.encodePacked(blockhash(block.number - 1)))) ^ roachContract.lastRoachId();
        _randomCallback(account, seed);
    }

}
