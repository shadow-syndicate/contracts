// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/access/Ownable.sol";

contract USDClub is ERC20, Ownable {
    constructor()
        ERC20("United Sex Dolls Club", "USDC")
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
