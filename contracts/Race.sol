// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";

contract Race is Operators {

    event Register(uint indexed raceId, uint roachId, address token, uint entryFee);
    event RegisterFail(uint indexed raceId, uint roachId);
    event Withdraw(uint indexed raceId, uint roachId);

    uint public constant MAX_TRACK_COUNT = 10;

    struct RaceInfo {
        uint[] roaches;
        address token;
        uint bank;
    }

    mapping(uint => RaceInfo) public races;
    mapping(address => uint) public fees;
    IRoachNFT public nft;

    constructor (IRoachNFT _nft) {
        nft = _nft;
    }

    function register(uint raceId, uint roachId, address token, uint entryFee, uint deadline) external {
        // TODO: check signature

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
        races[raceId].bank += entryFee;
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

    function withdraw(uint raceId, uint roachId, uint value) external {
        // TODO: check signature
        _withdraw(raceId, roachId, value);
    }

    function _withdraw(uint raceId, uint roachId, uint value) internal {
        address payable playerAddress = payable(nft.ownerOf(roachId));

        RaceInfo storage race = races[raceId];

        require(race.bank >= value, 'Not enough funds in bank');

        for (uint i = 0; i < race.roaches.length; i++) {
            if (race.roaches[i] == roachId) {
                delete race.roaches[i];
                race.bank -= value;
                emit Withdraw(raceId, roachId);
                _sendMoney(playerAddress, race.token, value);
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

    function finishOperator(uint raceId, uint[] calldata roachId, uint[] calldata value) external onlyOperator {
        for (uint i = 0; i < roachId.length; i++) {
            _withdraw(raceId, roachId[i], value[i]);
        }
        RaceInfo storage race = races[raceId];
        fees[race.token] += race.bank;
        delete races[raceId];
    }

}
