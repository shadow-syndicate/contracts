// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract Sale is Operators {

    uint constant public ROACH_PRICE = 0.001 ether;
    uint constant public SALE_LIMIT = 10000;

    IERC20 public moneyTokenContract;
    IRoachNFT public roachContract;
    uint public soldCount = 0;

    // TODO: Whitelist & stages

    constructor(IERC20 _moneyToken, IRoachNFT _roachContract) {
        moneyTokenContract = _moneyToken;
        roachContract = _roachContract;
    }

    function buy(uint count) external {
        uint needMoney = ROACH_PRICE * count;

        // require(count > 0, 'Min count is 1'); TODO: check max count
        require(count > 0, 'Min count is 1');
        if (soldCount >= SALE_LIMIT) {
            require(false, 'Sale is over');
        }
        if (soldCount + count > SALE_LIMIT) {
            count = SALE_LIMIT - soldCount; // allow to buy left tokens
        }
        require(moneyTokenContract.balanceOf(msg.sender) >= needMoney, "Insufficient money!");

        moneyTokenContract.transferFrom(
            msg.sender,
            address(this),
            needMoney
        );
        _mint(msg.sender, count);
    }

    function _mint(address to, uint count) internal {
        soldCount += count;
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(msg.sender);
        }
    }

    function mint(address to, uint count) external onlyOperator {
        _mint(to, count);
    }

}
