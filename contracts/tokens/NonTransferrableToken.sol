// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol";
import "../Operators.sol";
import "../../interfaces/IERC20Mintable.sol";

abstract contract NonTransferrableToken is ERC20, IERC20Mintable, Operators {

    mapping(address => bool) whitelistedFrom;
    mapping(address => bool) whitelistedTo;
    bool public allowAnyTransfers;

    constructor() {
        whitelistedFrom[address(0x0)] = true;
    }

    function mint(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function setAllowAnyTransfers(bool _enabled) external onlyOwner {
        allowAnyTransfers = _enabled;
    }

    function setWhitelistedTo(address _address) external onlyOperator {
        whitelistedTo[_address] = true;
    }

    function setWhitelistedFrom(address _address) external onlyOperator {
        whitelistedFrom[_address] = true;
    }

    function removeWhitelistedTo(address account) external onlyOperator {
        delete whitelistedTo[account];
    }

    function removeWhitelistedFrom(address account) external onlyOperator {
        delete whitelistedFrom[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(allowAnyTransfers || whitelistedFrom[from] || whitelistedTo[to], 'not whitelisted');
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnOperator(address account, uint256 amount) external onlyOperator {
        _burn(account, amount);
    }

    function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256) {
        if (whitelistedTo[spender]) {
            return ~uint256(0);
        } else {
            return ERC20.allowance(owner, spender);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal override {
        if (whitelistedTo[spender]) {
        } else {
            return ERC20._spendAllowance(owner, spender, value);
        }
    }
}
