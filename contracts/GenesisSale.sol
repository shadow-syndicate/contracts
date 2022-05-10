// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract GenesisSale is Operators {

    uint public ROACH_PRICE = 0.0001 ether;
    uint public TOTAL_TOKENS_ON_SALE = 10_000;
    uint constant public STAGE2_LIMIT_PER_TX = 30;
    uint public STAGE1_START;
    uint public STAGE1_DURATION;
    address public signerAddress;
    IRoachNFT public roachContract;

    mapping(address => uint) public soldCountPerAddress;
    mapping(string => uint) public syndicateScore;

    event Purchase(address indexed account, uint count, uint traitBonus, string syndicate);

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint price,
        uint totalTokensOnSale)
    {
        roachContract = _roachContract;
        STAGE1_START = stage1startTime;
        STAGE1_DURATION = stage1durationSeconds;
        ROACH_PRICE = price;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
        // TODO: setSigner
        signerAddress = msg.sender;
    }

    /// @notice Returns current sale status
    /// @param account Selected buyer address
    /// @return stage One of number 0..3. 0 - presale not started. 1 - Presale. 2 - Genesis sale. 3 - sale is over.
    /// @return leftToMint Left roaches to mint
    /// @return nextStageTimestamp UTC timestamp of current stage finish and next stage start. Always 0 for for stages 2 and 3.
    /// @return price One roach price in ETH.
    /// @return allowedToMint For stage 2 - max count for one tx.
    function getSaleStatus(address account, uint limitForAccount) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        uint price,
        uint allowedToMint)
    {
        stage = getSaleStage();

        price = ROACH_PRICE;
        nextStageTimestamp =
            stage == 0 ? STAGE1_START :
            stage == 1 ? STAGE1_START + STAGE1_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(totalSupply());
        allowedToMint =
            stage == 1 ? getAllowedToBuyForAccountOnPresale(account, limitForAccount) :
            stage == 2 ? getAllowedToBuyOnStage2() :
            (uint)(0);
    }

    function totalSupply() public view returns (uint256) {
        return roachContract.lastRoachId();
    }

    function isPresaleActive() public view returns (bool) {
        return STAGE1_START <= block.timestamp
            && block.timestamp < STAGE1_START + STAGE1_DURATION
            && totalSupply() < TOTAL_TOKENS_ON_SALE;
    }

    function isSaleStage2Active() public view returns (bool) {
        return STAGE1_START + STAGE1_DURATION <= block.timestamp
            && totalSupply() < TOTAL_TOKENS_ON_SALE;
    }

    function getSaleStage() public view returns (uint) {
        return isPresaleActive() ? 1 :
            isSaleStage2Active() ? 2 :
            block.timestamp < STAGE1_START ? 0 :
            3;
    }

    function getAllowedToBuyOnStage2() public pure returns (uint) {
        return STAGE2_LIMIT_PER_TX;
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param desiredCount The number of roach to mint
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    // decimals 2, 12 mean 12% bonus
    function mintStage1(
        uint desiredCount,
        uint limitForAccount,
        uint8 traitBonus,
        string calldata syndicate,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, traitBonus, sigV, sigR, sigS), "Wrong signature");
        _mintStage1(msg.sender, desiredCount, limitForAccount, traitBonus, syndicate);
    }

    function getAllowedToBuyForAccountOnPresale(address account, uint limitForAccount) public view returns (uint) {
        return limitForAccount > soldCountPerAddress[account]
            ? limitForAccount - soldCountPerAddress[account]
            : 0;
    }

    function _mintStage1(address account, uint desiredCount, uint limitForAccount, uint8 traitBonus, string calldata syndicate) internal {
        uint stage = getSaleStage();
        require(stage == 1, "Presale not active");
        uint leftToMint = getAllowedToBuyForAccountOnPresale(account, limitForAccount);
        require(desiredCount <= leftToMint, 'Account limit reached');

        _buy(account, desiredCount, syndicate, traitBonus);
    }

    /// @notice Takes payment and mints new roaches on Genesis Sale
    /// @dev function works on both Presale and Genesis sale stages
    /// @param desiredCount The number of roach to mint
    /// @param syndicate (Optional) Syndicate name, that player wants join to. Selected syndicate will receive a bonus.
    function mintStage2(uint desiredCount, string calldata syndicate) external payable {
        uint stage = getSaleStage();
        require(stage == 2, "Public sale not active");
        require(desiredCount <= STAGE2_LIMIT_PER_TX, 'Limit per tx');
        _buy(msg.sender, desiredCount, syndicate, 0);
    }

    function _buy(address account, uint count, string calldata syndicate, uint8 traitBonus) internal {
        require(count > 0, 'Min count is 1');
        uint soldCount = totalSupply();
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = ROACH_PRICE * count;
        syndicateScore[syndicate] += count;
        soldCountPerAddress[account] += count;
        emit Purchase(account, count, traitBonus, syndicate);
        _mintRaw(account, count, traitBonus, syndicate);
        acceptMoney(needMoney);
    }

    function acceptMoney(uint needMoney) internal {
        require(msg.value >= needMoney, "Insufficient money");
        if (msg.value > needMoney) {
            payable(msg.sender).transfer(msg.value - needMoney);
        }
    }

    function _mintRaw(address to, uint count, uint8 traitBonus, string calldata syndicate) internal {
        roachContract.mintGen0(to, count, traitBonus, syndicate);
    }

    /// Signatures

    function hashArguments(address account, uint limitForAccount, uint8 traitBonus)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount, traitBonus));
    }

    function getSigner(
        address account, uint limitForAccount, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
    public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount, traitBonus);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    function isValidSignature(
        address account, uint limitForAccount, uint8 traitBonus,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(account, limitForAccount, traitBonus, sigV, sigR, sigS) == signerAddress;
    }

    /// Admin functions
    function mintOperator(address to, uint count, uint8 traitBonus, string calldata syndicate) external onlyOperator {
        _mintRaw(to, count, traitBonus, syndicate);
    }

    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }
}
