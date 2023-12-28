// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.10;

import "../interfaces/IRoachNFT.sol";
import "./Operators.sol";
import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/IERC20.sol";

contract Unlocker is Operators {
    IRoachNFT public roachContract;
    IERC20 feeToken;

    constructor(IRoachNFT _roachContract, IERC20 _feeToken) {
        roachContract = _roachContract;
        feeToken = _feeToken;
    }

    function unlock(uint tokenId) external payable {
        require(roachContract.ownerOf(tokenId) == msg.sender, 'Wrong owner');
        (address tokenAddress, uint tokenValue) = getUnlockPrice();
        _takePayment(msg.sender, tokenAddress, tokenValue);
        roachContract.unlock(tokenId);
    }

    function getUnlockPrice() public view
        returns (address tokenAddress, uint tokenValue)
    {
        tokenAddress = address(feeToken);
        tokenValue = 0.01 ether;
    }

    function _takePayment(address user, address priceToken, uint priceValue) internal {
        if (priceValue > 0) {
            IERC20(priceToken).transferFrom(
                user,
                address(this),
                priceValue
            );
        }
    }
}
