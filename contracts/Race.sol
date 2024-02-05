// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/IRRC.sol";
import "../interfaces/IMutagen.sol";
import "../interfaces/IRefSystem.sol";

contract Race is Operators {

    event Register(uint indexed raceId, uint roachId, address token, uint entryFee);
    event RegisterFail(uint indexed raceId, uint roachId);
    event Claimed(uint[] raceId, uint[] roachId, address[] token, uint[] tokenValue, uint rrcValue, uint mutagenValue);

    uint public constant MAX_TRACK_COUNT = 10;
    uint public SYSTEM_FEE = 90;

    struct RaceInfo {
        uint[] roaches;
        address[] accounts;
        address token;
        uint tokenBank;
    }

    mapping(uint => RaceInfo) public races;
    mapping(address => uint) public fees;
    IRoachNFT public nft;
    IRRC public rrcToken;
    IMutagen public mutagenToken;
    IRefSystem refSystem;

    constructor (IRoachNFT _nft, IRRC _rrcToken, IMutagen _mutagenToken, IRefSystem _refSystem) {
        nft = _nft;
        rrcToken = _rrcToken;
        mutagenToken = _mutagenToken;
        refSystem = _refSystem;
    }

    function register(
        uint raceId,
        uint roachId,
        address token,
        uint entryFee,
        uint deadline,
        address uplink
    ) external {
        // TODO: check signature

        address account = msg.sender;

        //require(nft.ownerOf(roachId) == account, 'Wrong owner');
        require(nft.locked(roachId), 'Not locked');
        require(block.timestamp <= deadline, 'timeout');

        RaceInfo storage race = races[raceId];

        if (race.roaches.length >= MAX_TRACK_COUNT) {
            emit RegisterFail(raceId, roachId); // out of free slots
            return;
        }

        // check duplicated registration
        for (uint i = 0; i < race.roaches.length; i++) {
            require(race.roaches[i] != roachId, "Already registered");
            require(race.accounts[i] != account, "Already registered");
        }

        _acceptMoney(account, token, entryFee);

        races[raceId].roaches.push(roachId);
        races[raceId].accounts.push(account);
        races[raceId].token = token;
        races[raceId].tokenBank += entryFee;
        emit Register(raceId, roachId, token, entryFee);

        address[] memory accounts = new address[](1);
        accounts[0] = account;

        if (uplink != address(0x0)) {
            refSystem.registerUplink(account, uplink);
        }

        _reportFees(token, entryFee * SYSTEM_FEE / 100, accounts);
    }

    function _acceptMoney(address account, address token, uint needMoney) internal {
        if (token == address(0x0)) {
            require(msg.value >= needMoney, "Insufficient money");
        } else {
            IERC20(token).transferFrom(
                account,
                address(this),
                needMoney
            );
        }
    }

//    function claim(uint raceId, uint roachId, uint tokenValue, uint rrcValue, uint mutagenValue) external {
//        // TODO: check signature
//        _claim(raceId, roachId, tokenValue, rrcValue, mutagenValue);
//        uint[] memory raceIds = new uint[];
//        raceIds.push(raceId);
//        emit Claimed(raceIds, [roachId], [races[raceId].token], [tokenValue], [rrcValue], [mutagenValue]);
//    }

    function claimBatch(
        uint[] calldata raceId,
        uint[] calldata roachId,
        uint[] calldata tokenValue,
        uint[] calldata rrcValue,
        uint[] calldata mutagenValue
//        uint8 sigV,  // Stack too deep
//        bytes32 sigR,
//        bytes32 sigS
    )
    external
    {
        // TODO: check signature
        require(raceId.length == roachId.length, "raceId != roachId length");
        require(raceId.length == tokenValue.length, "raceId != tokenValue length");
        require(raceId.length == rrcValue.length, "raceId != rrcValue length");
        require(raceId.length == mutagenValue.length, "raceId != mutagenValue length");
        address[] memory tokens = new address[](raceId.length);
        uint totalRrcValue = 0;
        uint totalMutagenValue = 0;
        for (uint i = 0; i < raceId.length; i++) {
            _claim(raceId[i], roachId[i], msg.sender, tokenValue[i], rrcValue[i], mutagenValue[i]);
            tokens[i] = races[raceId[i]].token;
            totalRrcValue += rrcValue[i];
            totalMutagenValue += mutagenValue[i];
        }

        mutagenToken.mint(msg.sender, totalMutagenValue);
        rrcToken.mint(msg.sender, totalRrcValue);

        emit Claimed(raceId, roachId, tokens, tokenValue, totalRrcValue, totalMutagenValue);
    }

    function _claim(uint raceId, uint roachId, address account, uint tokenValue, uint rrcValue, uint mutagenValue) internal {
        // TODO: check rrcValue and mutagenValue
        address payable playerAddress = payable(account);

        RaceInfo storage race = races[raceId];

        require(race.tokenBank >= tokenValue, 'Not enough funds in bank');

        for (uint i = 0; i < race.roaches.length; i++) {
            if (race.roaches[i] == roachId) {
                require(account == race.accounts[i], 'Wrong claimer');
                delete race.roaches[i];
                race.tokenBank -= tokenValue;
                _sendMoney(playerAddress, race.token, tokenValue);
                return;
            }
        }
        revert('Player not found');
    }

    function _reportFees(address token, uint feePerAccount, address[] memory accounts) internal {
        uint needMoney = refSystem.reportFees(token, feePerAccount, accounts);
        require(needMoney <= feePerAccount * accounts.length, 'RegSystem bug');
        _sendMoney(payable(address(refSystem)), token, needMoney);
    }

    function _sendMoney(address payable account, address token, uint value) internal {
        if (token == address(0x0)) {
            account.transfer(value);
        } else {
            IERC20(token).transferFrom(
                address(this),
                account,
                value
            );
        }
    }

    function setSystemFee(uint _systemFee) external onlyOwner {
        SYSTEM_FEE = _systemFee;
    }

    function setRefSystem(IRefSystem _refSystem) external onlyOwner {
        refSystem = _refSystem;
    }
}
