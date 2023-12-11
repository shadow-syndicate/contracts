// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

interface IRefSystem {

    function reportFees(address token, uint feePerAccount, address[] calldata accounts) external returns (uint needMoney);
    function registerUplink(address downlink, address uplink) external;

}
