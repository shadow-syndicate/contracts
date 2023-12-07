// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

interface IRefSystemConfig {

    function getUplinkReward(address downlink, address uplink, address token, uint downlinkPayedFee)
        external view returns (address rewardToken, uint rewardValue);

}
