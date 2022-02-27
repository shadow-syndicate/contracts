// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract GenesisSale is Operators {

    struct Whitelist {
        uint16 maxCount;
        uint32 traitBonus; // decimals 2, 12 mean 12% bonus
    }

    uint public ROACH_PRICE = 0.001 ether;
    uint constant public SALE_LIMIT = 10_000;
    uint constant public STAGE2_LIMIT_PER_TX = 100;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;

    IERC20 public moneyTokenContract;
    IRoachNFT public roachContract;
    uint public soldCount = 0;
    mapping(address => uint) public soldCountPerAddress;
    mapping(address => Whitelist) public whitelist;
    mapping(string => uint) public syndicateScore;

    constructor(
        IERC20 _moneyToken,
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price)
    {
        moneyTokenContract = _moneyToken;
        roachContract = _roachContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        ROACH_PRICE = price;
    }

    function isPresaleActive() public view returns (bool) {
        return STAGE1_START <= block.timestamp
            && block.timestamp < STAGE1_START + STAGE1_DURATION;
    }

    function isSaleStage2Active() public view returns (bool) {
        return STAGE1_START + STAGE1_DURATION <= block.timestamp
            && soldCount < SALE_LIMIT;
    }

    function getSaleStatus(address account) external view returns (
        bool presaleActive,
        bool stage2active,
        uint leftToMint,
        uint secondsToNextStage,
        uint price,
        uint allowedToMintForAccount,
        uint accountBonus)
    {
        presaleActive = isPresaleActive();
        stage2active = isSaleStage2Active();
        price = ROACH_PRICE;
        secondsToNextStage =
            presaleActive ? STAGE1_START + STAGE1_DURATION - block.timestamp :
            block.timestamp < STAGE1_START ? STAGE1_START - block.timestamp :
            0;
        leftToMint = SALE_LIMIT - soldCount;
        allowedToMintForAccount =
            presaleActive ? getAllowedToBuyForAccountOnPresale(account) :
            stage2active ? getAllowedToBuyOnStage2() :
            (uint)(0);
        accountBonus = presaleActive ? getAccountBonusOnPresale(account) : (uint)(0);
    }

    function getAccountBonusOnPresale(address account) public view returns (uint) {
        return whitelist[account].traitBonus;
    }

    function getAllowedToBuyForAccountOnPresale(address account) public view returns (uint) {
        return whitelist[account].maxCount - soldCountPerAddress[account];
    }

    function getAllowedToBuyOnStage2() public view returns (uint) {
        return STAGE2_LIMIT_PER_TX;
    }

    function mint(uint count, string calldata syndicate) external {
        if (isPresaleActive()) {
            _mintStage1(msg.sender, count, syndicate);
        } else if (isSaleStage2Active()) {
            _mintStage2(msg.sender, count, syndicate);
        } else {
            revert("Genesis sale not started yet");
        }
    }

    function _mintStage1(address account, uint count, string calldata syndicate) internal {
        require(STAGE1_START <= block.timestamp, 'Sale stage1 not started');
        require(block.timestamp < STAGE1_START + STAGE1_DURATION, 'Sale stage1 is over');

        uint leftToMint = getAllowedToBuyForAccountOnPresale(account);
        require(count <= leftToMint, 'Account limit reached');

        soldCountPerAddress[account] += count;
        _buy(account, count, syndicate, whitelist[account].traitBonus);
    }

    function _mintStage2(address account, uint count, string calldata syndicate) internal {
        require(count <= STAGE2_LIMIT_PER_TX, 'Limit per tx');
        require(STAGE1_START + STAGE1_DURATION <= block.timestamp, 'Sale stage2 not started');
        _buy(account, count, syndicate, 0);
    }

    function _buy(address account, uint count, string calldata syndicate, uint32 traitBonus) internal {
        uint needMoney = ROACH_PRICE * count;

        require(count > 0, 'Min count is 1');
        if (soldCount >= SALE_LIMIT) {
            require(false, 'Sale is over');
        }
        if (soldCount + count > SALE_LIMIT) {
            count = SALE_LIMIT - soldCount; // allow to buy left tokens
        }
        require(moneyTokenContract.balanceOf(account) >= needMoney, "Insufficient money");

        moneyTokenContract.transferFrom(
            account,
            address(this),
            needMoney
        );
        syndicateScore[syndicate] += count;
        _mintRaw(account, count, traitBonus);
    }

    function _mintRaw(address to, uint count, uint32 traitBonus) internal {
        soldCount += count;
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(to, traitBonus);
        }
    }

    /// Admin functions

    function mintOperator(address to, uint count, uint32 traitBonus) external onlyOperator {
        _mintRaw(to, count, traitBonus);
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
