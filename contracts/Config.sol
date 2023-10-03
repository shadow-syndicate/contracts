// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;
import "./Operators.sol";
import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/IERC20.sol";

contract Config is Operators {
    IERC20 public mutagenToken;
    IERC20 public rrcToken;

    constructor (IERC20 _mutagenToken, IERC20 _rrcToken) {
        mutagenToken = _mutagenToken;
        rrcToken = _rrcToken;
    }

    function getBuySlotPrice(address user) external view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(rrcToken);
        tokenValue = 1 ether;
    }

    function getBreedPrice(uint40 parent) private view
        returns (uint mutagenValue)
    {
        return 100 ether;
    }

    function getInitPrice(uint40 parent0, uint40 parent1) external view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(mutagenToken);
        tokenValue = getBreedPrice(parent0) + getBreedPrice(parent1);
    }

    function getStartPrice(uint40 parent0, uint40 parent1) external view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(rrcToken);
        tokenValue = 50 ether;
    }

    function getRollPrice(uint rollNumber) external view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(rrcToken);
        tokenValue = 50 ether;
    }

    function getSpeedupPrice(uint leftTimeSeconds) external view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(rrcToken);
        uint leftMin = (leftTimeSeconds + 60 - 1) / 60;
        tokenValue = 1 ether * leftMin / 60 / 24; // 1 RRC per day, increase every hour
    }

    function isGoodBreedCount(uint breedCount) external view
        returns (bool)
    {
        return breedCount < 7;
    }

    function getRevealCooldown() external pure
        returns (uint)
    {
        return 5*60;
    }

    function getBreedSuccessProbability(uint rollNumber) external pure
        returns (uint percent)
    {
        int result = 100 - 5 * int(rollNumber);
        percent = result < 50 ? 50 : uint(result);
    }

}
