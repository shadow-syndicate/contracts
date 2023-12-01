// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/IRRC.sol";
import "../interfaces/IMutagen.sol";

contract Race is Operators {

    event Register(uint indexed raceId, uint roachId, address token, uint entryFee);
    event RegisterFail(uint indexed raceId, uint roachId);
    event Claimed(uint[] raceId, uint[] roachId, address[] token, uint[] tokenValue, uint rrcValue, uint mutagenValue);

    uint public constant MAX_TRACK_COUNT = 10;

    struct RaceInfo {
        uint[] roaches;
        address token;
        uint tokenBank;
    }

    mapping(uint => RaceInfo) public races;
    mapping(address => uint) public fees;
    IRoachNFT public nft;
    IRRC public rrcToken;
    IMutagen public mutagenToken;

    constructor (IRoachNFT _nft, IRRC _rrcToken, IMutagen _mutagenToken) {
        nft = _nft;
        rrcToken = _rrcToken;
        mutagenToken = _mutagenToken;
    }

    function register(uint raceId, uint roachId, address token, uint entryFee, uint deadline) external {
        // TODO: check signature
        // TODO: check ownership/lock

        RaceInfo storage race = races[raceId];

        if (race.roaches.length >= MAX_TRACK_COUNT) {
            emit RegisterFail(raceId, roachId);
            return;
        }

        for (uint i = 0; i < race.roaches.length; i++) {
            require(race.roaches[i] != roachId, "Already registered");
        }

        _acceptMoney(msg.sender, token, entryFee);

        races[raceId].roaches.push(roachId);
        races[raceId].token = token;
        races[raceId].tokenBank += entryFee;
        emit Register(raceId, roachId, token, entryFee);
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
        uint[] calldata mutagenValue)
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
            _claim(raceId[i], roachId[i], tokenValue[i], rrcValue[i], mutagenValue[i]);
            tokens[i] = races[raceId[i]].token;
            totalRrcValue += rrcValue[i];
            totalMutagenValue += mutagenValue[i];
        }

        mutagenToken.mint(msg.sender, totalMutagenValue);
        rrcToken.mint(msg.sender, totalRrcValue);

        emit Claimed(raceId, roachId, tokens, tokenValue, totalRrcValue, totalMutagenValue);
    }

    function _claim(uint raceId, uint roachId, uint tokenValue, uint rrcValue, uint mutagenValue) internal {
        // TODO: check rrcValue and mutagenValue
        address payable playerAddress = payable(nft.ownerOf(roachId));

        RaceInfo storage race = races[raceId];

        require(race.tokenBank >= tokenValue, 'Not enough funds in bank');

        for (uint i = 0; i < race.roaches.length; i++) {
            if (race.roaches[i] == roachId) {
                delete race.roaches[i];
                race.tokenBank -= tokenValue;
                _sendMoney(playerAddress, race.token, tokenValue);
                return;
            }
        }
        revert('Player not found');
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

}
