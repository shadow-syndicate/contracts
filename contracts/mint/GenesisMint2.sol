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

import "../Operators.sol";
import "../../interfaces/IRoachNFT.sol";
import "../../interfaces/IERC20Mintable.sol";

/// @title Genesis collection mint for TRAX contract
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Distribute 10k tokens for TRAX tokens
abstract contract GenesisMint2 is Operators {

    IRoach public roachContract;
    IERC20Mintable traxToken;
    uint public MINT_START;
    uint public MINT_DURATION = 0; // unlimited by default
    uint public TOTAL_TOKENS_TO_MINT = 10_000;
    uint public PRICE = 1 ether;
    uint public BASE_PROBABILITY = 50*100;
    address public signerAddress;

    event Mint(address indexed account, uint indexed roachId, uint ethValue);
    event MintRequest(address indexed account, uint ethValue);
    event MintTraxSuccess(address indexed account, uint indexed roachId);
    event MintTraxFail(address indexed account);

    function _requestRandomForMint(address account) virtual internal;

    constructor(
        IRoach _roachContract,
        IERC20Mintable _traxToken,
        uint stage1startTime)
    {
        roachContract = _roachContract;
        traxToken = _traxToken;
        MINT_START = stage1startTime;
    }

    function getMintStatus(address account, uint whitelistLimitForAccount) external view returns (
        uint stage,
        int leftToMint,
        uint nextStageTimestamp,
        int allowedToMint,
        uint price)
    {
        stage = getMintStage();

        nextStageTimestamp =
            stage == 0 ? MINT_START :
                stage == 1 && MINT_DURATION > 0 ? MINT_START + MINT_DURATION :
                    0;
        leftToMint = int(TOTAL_TOKENS_TO_MINT) - int(totalMinted());
        allowedToMint =
            stage == 1 ? (int)(getAllowedToMintForAccount(account, whitelistLimitForAccount)) :
                int(0);
        price = getRoachPriceInTrax();
    }

    function totalMinted() public view returns (uint256) {
        return roachContract.lastRoachId();
    }

    function isMintActive() public view returns (bool) {
        return MINT_START <= block.timestamp
        && (block.timestamp < MINT_START + MINT_DURATION || MINT_DURATION == 0)
            && totalMinted() < TOTAL_TOKENS_TO_MINT;
    }

    /// @return stage One of number 0..2: 0 - mint not started. 1 - Mint. 2 - mint is over.
    function getMintStage() public view returns (uint) {
        return isMintActive() ? 1 :
            block.timestamp < MINT_START ? 0 :
                2;
    }

    function mintWhitelisted(
        uint limitForAccount,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external payable
    {
        require(isValidSignature(msg.sender, limitForAccount, sigV, sigR, sigS), "Wrong signature");
        _mint(msg.sender, limitForAccount);
    }

    function getAllowedToMintForAccount(address account, uint limitForAccount) public view returns (uint) {
        uint256 numberMinted = roachContract.getNumberMinted(account);
        return limitForAccount > numberMinted
            ? limitForAccount - numberMinted
            : 0;
    }

    function _mint(
        address account,
        uint limitForAccount)
        internal
    {
        uint stage = getMintStage();
        require(stage == 1, "Mint not active");
        uint leftToMint = getAllowedToMintForAccount(account, limitForAccount);
        require(1 <= leftToMint, 'Account limit reached');

        uint soldCount = totalMinted();
        _mintRaw(account, 1);
        emit Mint(account, roachContract.lastRoachId(), msg.value);
    }

    function _mintRaw(address to, uint count) internal {
        roachContract.mintGen0(to, count);
    }

    /// TRAX

    function mintForTrax()
        external payable
    {
        require(!_isCalledFromContract(), "Called from another contract");
        _takePayment(msg.sender, traxToken, getRoachPriceInTrax());

        // TODO: check TRAX
        uint stage = getMintStage();
        require(stage == 1, "Mint not active");

        _requestRandomForMint(msg.sender);
        emit MintRequest(msg.sender, msg.value);
    }


    function _randomCallback(address account, uint seed)
        internal
    {
        uint stage = getMintStage();

        if (stage != 1) {
            // Mint not active
            emit MintTraxFail(account);
            return;
        }

        uint probality = getMintProbability();
        uint dice = seed % 10000;
        if (dice < probality) {
            _mintRaw(account, 1);
            emit MintTraxSuccess(account, roachContract.lastRoachId());
        } else {
            emit MintTraxFail(account);
        }
    }

    function getMintProbability() public view returns (uint) {
        return BASE_PROBABILITY;
    }

    function getRoachPriceInTrax() public view returns (uint) {
        return PRICE;
    }

    /// Signatures

    /// @notice Internal function used in signature checking
    function hashArguments(address account, uint limitForAccount)
        public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(account, limitForAccount));
    }

    /// @notice Internal function used in signature checking
    function getSigner(
        address account, uint limitForAccount,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public pure returns (address)
    {
        bytes32 msgHash = hashArguments(account, limitForAccount);
        return ecrecover(msgHash, sigV, sigR, sigS);
    }

    /// @notice Internal function used in signature checking
    function isValidSignature(
        address account, uint limitForAccount,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    )
        public view returns (bool)
    {
        return getSigner(account, limitForAccount, sigV, sigR, sigS) == signerAddress;
    }

    /// @notice Changes secret key that is used for signature generation
    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }

    function setPrice(uint _price) external onlyOwner {
        PRICE = _price;
    }

    /// @notice Mints new NFT with selected parameters
    /// @dev There is a guarantee that there will no more than 10k genesis roaches
    function mintOperator(address to, uint count) external onlyOperator {
        uint _totalMinted = totalMinted();
        require(_totalMinted + count <= TOTAL_TOKENS_TO_MINT, "Mint is over");
        _mintRaw(to, count);
    }

    function mintLeftOperator(address to) external onlyOperator {
        uint _totalMinted = totalMinted();
        require(_totalMinted < TOTAL_TOKENS_TO_MINT, "Mint is over");
        uint count = TOTAL_TOKENS_TO_MINT - _totalMinted;
        _mintRaw(to, count);
    }

    function _isCalledFromContract() view internal returns (bool) {
        return tx.origin != msg.sender;
    }

    function _takePayment(address user, IERC20 priceToken, uint priceValue) internal {
        if (priceValue > 0) {
            priceToken.transferFrom(
                user,
                address(this),
                priceValue
            );
        }
    }

}
