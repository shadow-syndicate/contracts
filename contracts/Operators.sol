// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.0/contracts/access/Ownable.sol";

/// @title Helper contract for contract maintainance
/// @author Shadow Syndicate / Andrey Pelipenko (kindex@kindex.lv)
contract Operators is Ownable {
    mapping (address=>bool) operatorAddress;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner() == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || isOwner(_addr);
    }

    function _addOperator(address _newOperator) internal {
        operatorAddress[_newOperator] = true;
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");
        _addOperator(_newOperator);
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Owner can claim any tokens that are transferred
     * to this contract address
     */
    function withdrawERC20(IERC20 _tokenContract, address _admin) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_admin, balance);
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
