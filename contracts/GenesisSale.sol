// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract GenesisSale is Operators {

    struct Whitelist {
        uint16 maxCount;
        uint8 traitBonus; // decimals 2, 12 mean 12% bonus
    }

    uint public ROACH_PRICE = 0.0001 ether;
    uint public TOTAL_TOKENS_ON_SALE = 10_000;
    uint constant public STAGE2_LIMIT_PER_TX = 30;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;

    IERC20 public moneyTokenContract;
    IRoachNFT public roachContract;
    uint public soldCount = 0;
    mapping(address => uint) public soldCountPerAddress;
    mapping(address => Whitelist) public whitelist;
    mapping(string => uint) public syndicateScore;

    event Purchase(address indexed account, uint count, uint traitBonus, string syndicate);

    constructor(
        IERC20 _moneyToken,
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
    {
        moneyTokenContract = _moneyToken;
        roachContract = _roachContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        ROACH_PRICE = price;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param count The number of roach to mint
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    function mint(uint count, string calldata syndicate) external {
        uint stage = getSaleStage();
        if (stage == 1) {
            _mintStage1(msg.sender, count, syndicate);
        } else if (stage == 2) {
            _mintStage2(msg.sender, count, syndicate);
        } else if (stage == 0) {
            revert("Sale not started yet");
        } else {
            revert("Sale is over");
        }
    }

    /// @notice Returns current sale status
    /// @param account Selected buyer address
    /// @return stage One of number 0..3. 0 - presale not started. 1 - Presale. 2 - Genesis sale. 3 - sale is over.
    /// @return leftToMint Left roaches to mint
    /// @return nextStageTimestamp UTC timestamp of current stage finish and next stage start. Always 0 for for stages 2 and 3.
    /// @return price One roach price in WETH.
    /// @return allowedToMint For stage 1 - left roaches to mint for selected buyer address. For stage 2 - max count for one tx.
    /// @return accountBonus Selected buyer address bonus for rare trait probability
    function getSaleStatus(address account) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        uint price,
        uint allowedToMint,
        uint accountBonus)
    {
        stage = getSaleStage();

        price = ROACH_PRICE;
        nextStageTimestamp =
            stage == 0 ? STAGE1_START :
            stage == 1 ? STAGE1_START + STAGE1_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(soldCount);
        allowedToMint =
            stage == 1 ? getAllowedToBuyForAccountOnPresale(account) :
            stage == 2 ? getAllowedToBuyOnStage2() :
            (uint)(0);
        accountBonus = stage <= 1 ? getAccountBonusOnPresale(account) : (uint)(0);
    }

    function isPresaleActive() public view returns (bool) {
        return STAGE1_START <= block.timestamp
            && block.timestamp < STAGE1_START + STAGE1_DURATION
            && soldCount < TOTAL_TOKENS_ON_SALE;
    }

    function isSaleStage2Active() public view returns (bool) {
        return STAGE1_START + STAGE1_DURATION <= block.timestamp
            && soldCount < TOTAL_TOKENS_ON_SALE;
    }

    function getSaleStage() public view returns (uint) {
        return isPresaleActive() ? 1 :
            isSaleStage2Active() ? 2 :
            block.timestamp < STAGE1_START ? 0 :
            3;
    }

    function getAccountBonusOnPresale(address account) public view returns (uint) {
        return whitelist[account].traitBonus;
    }

    function getAllowedToBuyForAccountOnPresale(address account) public view returns (uint) {
        return whitelist[account].maxCount - soldCountPerAddress[account];
    }

    function getAllowedToBuyOnStage2() public pure returns (uint) {
        return STAGE2_LIMIT_PER_TX;
    }

    function _mintStage1(address account, uint count, string calldata syndicate) internal {
        uint leftToMint = getAllowedToBuyForAccountOnPresale(account);
        require(count <= leftToMint, 'Account limit reached');

        _buy(account, count, syndicate, whitelist[account].traitBonus);
    }

    function _mintStage2(address account, uint count, string calldata syndicate) internal {
        require(count <= STAGE2_LIMIT_PER_TX, 'Limit per tx');
        _buy(account, count, syndicate, 0);
    }

    function _buy(address account, uint count, string calldata syndicate, uint8 traitBonus) internal {
        require(count > 0, 'Min count is 1');
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = ROACH_PRICE * count;
        uint balance = moneyTokenContract.balanceOf(account);
        if (balance < needMoney) {
            // Allow to buy less roaches when money are less than needed for requested count
            count = balance / ROACH_PRICE;
            needMoney = ROACH_PRICE * count;
            require(count > 0, "Insufficient money");
        }

        moneyTokenContract.transferFrom(
            account,
            address(this),
            needMoney
        );
        syndicateScore[syndicate] += count;
        soldCountPerAddress[account] += count;
        emit Purchase(account, count, traitBonus, syndicate);
        _mintRaw(account, count, traitBonus);
    }

    function _mintRaw(address to, uint count, uint8 traitBonus) internal {
        soldCount += count;
        for (uint i = 0; i < count; i++) {
            roachContract.mintGen0(to, traitBonus);
        }
    }

    /// Admin functions

    function setWhitelistAddress(address account, uint16 maxCount, uint8 traitBonus) external onlyOperator {
        whitelist[account] = Whitelist(maxCount, traitBonus);
    }

    function setWhitelistAddressBatch(address[] calldata accounts, uint16 maxCount, uint8 traitBonus) external onlyOperator {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = Whitelist(maxCount, traitBonus);
        }
    }

    function mintOperator(address to, uint count, uint8 traitBonus) external onlyOperator {
        _mintRaw(to, count, traitBonus);
    }

}
