// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/ERC20.sol";
import "../Operators.sol";

abstract contract NonTransferrableToken is ERC20, Operators {

    mapping(address => bool) whitelisted;
    bool public allowAnyTransfers;

    function mint(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function setAllowAnyTransfers(bool _enabled) external onlyOwner {
        allowAnyTransfers = _enabled;
    }

    function setWhitelisted(address _address) external onlyOperator {
        whitelisted[_address] = true;
    }

    function removeWhitelisted(address account) external onlyOperator {
        delete whitelisted[account];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(allowAnyTransfers || whitelisted[from] || whitelisted[to], 'not whitelisted');
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnOperator(address account, uint256 amount) external onlyOperator {
        _burn(account, amount);
    }

}
