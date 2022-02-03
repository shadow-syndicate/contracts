// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract Sale is Operators {

    struct Whitelist {
        uint16 maxCount;
        uint32 traitBonus; // decimals 2, 12 mean 12% bonus
    }

    uint constant public ROACH_PRICE = 0.001 ether;
    uint constant public SALE_LIMIT = 10_000;
    uint STAGE1_START;
    uint STAGE1_DURATION;

    IERC20 public moneyTokenContract;
    IRoachNFT public roachContract;
    uint public soldCount = 0;
    mapping(address => uint) soldCountPerAddress;
    mapping(address => Whitelist) whitelist;
    mapping(string => uint) syndicateScore;

    // TODO: Whitelist & stages

    constructor(IERC20 _moneyToken, IRoachNFT _roachContract, uint stage1start, uint stage1duration) {
        moneyTokenContract = _moneyToken;
        roachContract = _roachContract;
        STAGE1_START = stage1start;
        STAGE1_DURATION = stage1duration;
    }

    function buyStage1(uint count, string calldata syndicate) external {
        require(STAGE1_START >= block.timestamp, 'Sale stage1 not started');
        require(STAGE1_START + STAGE1_DURATION < block.timestamp, 'Sale stage1 is over');

        uint limit = whitelist[msg.sender].maxCount;
        require(soldCountPerAddress[msg.sender] + count <= limit, 'Account limit reached');

        soldCountPerAddress[msg.sender] += count;
        _buy(count, syndicate, whitelist[msg.sender].traitBonus);
    }

    function buyStage2(uint count, string calldata syndicate) external {
        require(count <= 10, 'Max 10 nft per tx');
        require(STAGE1_START + STAGE1_DURATION >= block.timestamp, 'Sale stage1 not started');
        _buy(count, syndicate, 0);
    }

    function _buy(uint count, string calldata syndicate, uint32 traitBonus) internal {
        uint needMoney = ROACH_PRICE * count;

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
        syndicateScore[syndicate] += count;
        _mint(msg.sender, count, traitBonus);
    }

    function _mint(address to, uint count, uint32 traitBonus) internal {
        soldCount += count;
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(msg.sender, traitBonus);
        }
    }

    function mint(address to, uint count, uint32 traitBonus) external onlyOperator {
        _mint(to, count, traitBonus);
    }

    function setWhitelistAddress(address account, uint16 maxCount, uint32 traitBonus) external onlyOperator {
        whitelist[account] = Whitelist(maxCount, traitBonus);
    }

    function setWhitelistAddressBatch(address[] calldata accounts, uint16 maxCount, uint32 traitBonus) external onlyOperator {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = Whitelist(maxCount, traitBonus);
        }
    }
}
