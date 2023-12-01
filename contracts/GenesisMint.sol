// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
/*
                                                                   ..::--------::..
                                                               .:--------------------::
                                                            :----------------------------:
                                                         .:---------------------------------.
                                                        :-------------------------------------
                                                      .----------------------------------------:
                                                     :------------------------------------------:
                                                    :--===----------------------------------===--:
                                                   .--+@@@@%%#+=----------------------=+*#%@@@@+--:
                                                   ---@@@@@@@@@@@#+----------------+#@@@@@@@@@@@=--
                                                  :--+@@@@@@@@@@@@@@#+----------=#@@@@@@@@@@@@@@*--:
                                                  ---#@@@@@@@@@@@@@@@@%+------=%@@@@@@@@@@@@@@@@%---
                                                  -----==+*%@@@@@@@@@@@@%=--=#@@@@@@@@@@@@%*++=-----
                                                  -----------=*@@@@@@@@@@@*+@@@@@@@@@@@#+-----------
                                                  :-------------+%@@@@@@@@@@@@@@@@@@%+-------------:
                                                   ---------------*@@@@@@@@@@@@@@@@*---------------
                                                   :---------------=@@@@@@@@@@@@@@+---------------:
                                                    :---------------=@@@@@@@@@@@@=----------------
                                                     :---------------+@@@@@@@@@@*---------------:
                                                      :---------------%@@@@@@@@@---------------:
                                                        --------------#@@@@@@@@%--------------.
                                                         .------------#@@@@@@@@#------------.
                                                            :---------*@@@@@@@@#---------:.
                                                               :----------------------:.
                                                                     ..::--------:::.



███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗    ███████╗██╗   ██╗███╗   ██╗██████╗ ██╗ ██████╗ █████╗ ████████╗███████╗    ██╗███╗   ██╗ ██████╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║    ██╔════╝╚██╗ ██╔╝████╗  ██║██╔══██╗██║██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ██║████╗  ██║██╔════╝
███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║    ███████╗ ╚████╔╝ ██╔██╗ ██║██║  ██║██║██║     ███████║   ██║   █████╗      ██║██╔██╗ ██║██║
╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║    ╚════██║  ╚██╔╝  ██║╚██╗██║██║  ██║██║██║     ██╔══██║   ██║   ██╔══╝      ██║██║╚██╗██║██║
███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝    ███████║   ██║   ██║ ╚████║██████╔╝██║╚██████╗██║  ██║   ██║   ███████╗    ██║██║ ╚████║╚██████╗██╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝

*/

pragma solidity ^0.8.10;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

/// @title Genesis collection sale contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Distribute 10k tokens with arbitrary price to whitelisted accounts with limit
contract GenesisMint is Operators {

    uint public TOTAL_TOKENS_ON_SALE = 10_000;
    uint public SALE_START;
    uint public SALE_DURATION;
    address public signerAddress;
    IRoachNFT public roachContract;

    event Purchase(address indexed account, uint count, uint ethValue);

    constructor(
        IRoachNFT _roachContract,
        uint stage1startTime,
        uint stage1durationSeconds,
        uint totalTokensOnSale)
    {
        roachContract = _roachContract;
        SALE_START = stage1startTime;
        SALE_DURATION = stage1durationSeconds;
        TOTAL_TOKENS_ON_SALE = totalTokensOnSale;
        signerAddress = msg.sender;
    }

    /// @notice Returns current sale status
    /// @param account Selected buyer address
    /// @return stage One of number 0..3: 0 - presale not started. 1 - Presale. 2 - Public sale. 3 - sale is over.
    /// @return leftToMint Left roaches to mint in total
    /// @return nextStageTimestamp UNIX time of current stage finish and next stage start. Always 0 for for stages 2 and 3.
    /// @return price One roach price in ETH.
    /// @return allowedToMint For stage 2 - max count for one tx.
    function getSaleStatus(address account, uint limitForAccount) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        uint price,
        int allowedToMint)
    {
        stage = getSaleStage();

        price = 0;
        nextStageTimestamp =
            stage == 0 ? SALE_START :
            stage == 1 ? SALE_START + SALE_DURATION :
            0;
        leftToMint = int(TOTAL_TOKENS_ON_SALE) - int(totalMinted());
        allowedToMint =
            stage == 1 ? (int)(getAllowedToBuyForAccount(account, limitForAccount)) :
            int(0);
    }

    /// @notice Total number of minted tokens
    function totalMinted() public view returns (uint256) {
        return roachContract.lastRoachId();
    }

    function isPresaleActive() public view returns (bool) {
        return SALE_START <= block.timestamp
            && block.timestamp < SALE_START + SALE_DURATION
            && totalMinted() < TOTAL_TOKENS_ON_SALE;
    }

    /// @return stage One of number 0..3: 0 - presale not started. 1 - Sale. 3 - sale is over.
    function getSaleStage() public view returns (uint) {
        return isPresaleActive() ? 1 :
            block.timestamp < SALE_START ? 0 :
            2;
    }

    /// @notice Takes payment and mints new roaches on Presale Sale.
    /// @dev    Function checks signature, generated by backend for buyer account according to whitelist limitations.
    ///         Can be called twice if total minted token count doesn't exceed limitForAccount.
    /// @param desiredCount The number of roach to mint
    /// @param limitForAccount Original buy limit from whitelist
    /// @param price One roach price from whitelist
    /// @param sigV sigR sigS Signature that can be generated only by secret key, stored on game backend
    function mint(
        uint desiredCount,
        uint limitForAccount,
        uint price,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, price, sigV, sigR, sigS), "Wrong signature");
        _mint(msg.sender, desiredCount, limitForAccount, price);
    }

    /// @notice returns left allowed tokens for minting on Presale if purchase is preformed using several transaction
    function getAllowedToBuyForAccount(address account, uint limitForAccount) public view returns (uint) {
        uint256 numberMinted = roachContract.getNumberMinted(account);
        return limitForAccount > numberMinted
            ? limitForAccount - numberMinted
            : 0;
    }

    function _mint(
        address account,
        uint desiredCount,
        uint limitForAccount,
        uint price)
        internal
    {
        uint stage = getSaleStage();
        require(stage == 1, "Sale not active");
        uint leftToMint = getAllowedToBuyForAccount(account, limitForAccount);
        require(desiredCount <= leftToMint, 'Account limit reached');

        _buy(account, desiredCount, price);
    }

    function _buy(address account, uint count, uint price) internal {
        require(count > 0, 'Min count is 1');
        uint soldCount = totalMinted();
        if (soldCount + count > TOTAL_TOKENS_ON_SALE) {
            count = TOTAL_TOKENS_ON_SALE - soldCount; // allow to buy left tokens
        }
        uint needMoney = price * count;
        emit Purchase(account, count, msg.value);
        _mintRaw(account, count);
        _acceptMoney(needMoney);
    }

    function _acceptMoney(uint needMoney) internal {
        require(msg.value >= needMoney, "Insufficient money");
    }

    function _mintRaw(address to, uint count) internal {
        roachContract.mintGen0(to, count);
    }

    /// Signatures

    /// @notice Internal function used in signature checking
    function hashArguments(address account, uint limitForAccount, uint price)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount, price));
    }

    /// @notice Internal function used in signature checking
    function getSigner(
        address account, uint limitForAccount, uint price,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount, price);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    /// @notice Internal function used in signature checking
    function isValidSignature(
        address account, uint limitForAccount, uint price,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public
        view
        returns (bool)
    {
        return getSigner(account, limitForAccount, price, sigV, sigR, sigS) == signerAddress;
    }

    /// @notice Mints new NFT with selected parameters
    /// @dev There is a guarantee that there will no more than 10k genesis roaches
    function mintOperator(address to, uint count) external onlyOperator {
        uint soldCount = totalMinted();
        require(soldCount + count <= TOTAL_TOKENS_ON_SALE, "Sale is over");
        _mintRaw(to, count);
    }

    /// @notice Changes secret key that is used for signature generation
    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

}
