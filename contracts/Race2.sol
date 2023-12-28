// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)

pragma solidity ^0.8.18;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/IRRC.sol";
import "../interfaces/IMutagen.sol";
import "../interfaces/IERC20Mintable.sol";
import "../interfaces/IRefSystem.sol";

contract Race2 is Operators {

    event Register(uint indexed raceId, uint roachId, address token, uint entryFee);
    event RegisterFail(uint indexed raceId, uint roachId);
    event Finished(uint raceId);
    event Aborted(uint raceId);
    event RaceNotFound(uint raceId);

    uint public constant MAX_TRACK_COUNT = 10;

    struct RaceInfo {
        uint[] roaches;
        address[] accounts;
        address token;
        uint tokenBank;
    }

    mapping(uint => RaceInfo) public races;
    mapping(address => uint) public fees;
    IRoachNFT public nft;
    IRefSystem refSystem;
    IERC20Mintable public karmaToken;
    uint karmaBonus = 1 ether;
    address public signerAddress;

    constructor (IRoachNFT _nft, IRefSystem _refSystem, IERC20Mintable _karmaToken) {
        nft = _nft;
        refSystem = _refSystem;
        karmaToken = _karmaToken;
        signerAddress = msg.sender;
    }

    function setRefSystem(IRefSystem _refSystem) external onlyOwner {
        refSystem = _refSystem;
    }

    function setkarmaBonus(IERC20Mintable _karmaToken, uint _karmaBonus) external onlyOwner {
        karmaToken = _karmaToken;
        karmaBonus =  _karmaBonus;
    }

    function register(
        uint raceId,
        uint roachId,
        address token,
        uint entryFee,
        uint deadline,
        address uplink,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) external {
        require(isValidSigRegister(raceId, roachId, token, entryFee, deadline, uplink, sigV, sigR, sigS), 'invalid sig');

        _register(msg.sender, raceId, roachId, token, entryFee, deadline, uplink);
    }

    function reportAndRegister(
        uint[] calldata uintArgs, // raceId, roachId, entryFee, deadline, reportRaceId, sigV
        address[] calldata addressArgs, // token, uplink, bonusToken

        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        uint[] calldata bonusValue,

        bytes32 sigR,
        bytes32 sigS
    ) external
    {
        require(isValidSigReportAndRegister(uintArgs, addressArgs, leaderboard, bankRewards, bonusValue, sigR, sigS),
            'invalid sig');
        _reportRaceFinish(uintArgs[4], leaderboard, bankRewards, IERC20Mintable(addressArgs[2]), bonusValue);
        _registerPacked(msg.sender, uintArgs, addressArgs);
    }

    function _registerPacked(
        address account,
        uint[] calldata uintArgs,
        address[] calldata addressArgs)
    internal {
        _register(account, uintArgs[0], uintArgs[1], addressArgs[0], uintArgs[2], uintArgs[3], addressArgs[1]);
    }

    function _register(
        address account,
        uint raceId,
        uint roachId,
        address token,
        uint entryFee,
        uint deadline,
        address uplink) internal
    {
        // require(nft.ownerOf(roachId) == account, 'Wrong owner');
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

        if (uplink != address(0x0)) {
            refSystem.registerUplink(account, uplink);
        }
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

    function _mintKarma(address account) internal {
        karmaToken.mint(account, karmaBonus);
    }

    function reportRaceAborted(uint raceId, uint8 sigV, bytes32 sigR, bytes32 sigS) external {
        require (isValidSigReportRaceAborted(raceId, sigV, sigR, sigS), 'invalid sig');
        if (_reportRaceAborted(raceId)) {
            _mintKarma(msg.sender);
        }
    }

    function reportRaceAbortedOperator(uint raceId) external onlyOperator {
        _reportRaceAborted(raceId);
    }

    function _reportRaceAborted(uint raceId) internal returns (bool success){
        RaceInfo storage race = races[raceId];
        if (race.accounts.length == 0) {
            // maybe race abort has been already called
            // do not fail duplicated transaction, just emit event
            emit RaceNotFound(raceId);
            return false;
        }
        if (race.tokenBank > 0) {
            uint entryFee = race.tokenBank / race.accounts.length;
            for (uint i = 0; i < race.accounts.length; i++) {
                _sendMoney(payable(race.accounts[i]), race.token, entryFee);
            }
        }
        emit Aborted(raceId);
        delete races[raceId];
        return true;
    }

    function reportRaceFinish(
        uint raceId,
        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        IERC20Mintable bonusToken,
        uint[] calldata bonusValue,
        uint8 sigV, bytes32 sigR, bytes32 sigS
    ) external
    {
        require(isValidSigReportRaceFinish(raceId, leaderboard, bankRewards, bonusToken, bonusValue, sigV, sigR, sigS),
            'invalid sig');
        if (_reportRaceFinish(raceId, leaderboard, bankRewards, bonusToken, bonusValue)) {
            _mintKarma(msg.sender);
        }
    }

    function reportRaceFinishOperator(
        uint raceId,
        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        IERC20Mintable bonusToken,
        uint[] calldata bonusValue
    ) external onlyOperator
    {
        _reportRaceFinish(raceId, leaderboard, bankRewards, bonusToken, bonusValue);
    }

    function _reportRaceFinish(
        uint raceId,
        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        IERC20Mintable bonusToken,
        uint[] calldata bonusValue
    ) internal returns (bool success) {
        RaceInfo storage race = races[raceId];
        if (race.accounts.length == 0) {
            // maybe rewards distribution has been already called
            // do not fail duplicated transaction, just emit event
            emit RaceNotFound(raceId);
            return false;
        }

        if (race.tokenBank > 0) {
            for (uint i = 0; i < bankRewards.length; i++) {
                uint bankReward = bankRewards[i];
                require(race.tokenBank >= bankReward, 'Not enough money for reward');
                _sendMoney(leaderboard[i], race.token, bankReward);
                race.tokenBank -= bankReward;
            }
            uint systemFee = race.tokenBank;
            _reportFees(race.token, systemFee / race.accounts.length, race.accounts);
        }

        // TODO: safe check bonus value according to left fees
        for (uint i = 0; i < bonusValue.length; i++) {
            bonusToken.mint(leaderboard[i], bonusValue[i]);
        }

        emit Finished(raceId);
        delete races[raceId];
        return true;
    }

    function _reportFees(address token, uint feePerAccount, address[] storage accounts) internal {
        uint needMoney = refSystem.reportFees(token, feePerAccount, accounts);
        require(needMoney <= feePerAccount * accounts.length, 'RegSystem bug');
        _sendMoney(payable(address(refSystem)), token, needMoney);
    }

    function _sendMoney(address payable account, address token, uint value) internal {
        if (value == 0) {
            return;
        }
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

    function isValidSigReportRaceAborted(uint raceId, uint8 sigV, bytes32 sigR, bytes32 sigS) public view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(raceId));
        return ecrecover(msgHash, sigV, sigR, sigS) == signerAddress;
    }

    function isValidSigReportAndRegister(
        uint[] calldata uintArgs, // raceId, roachId, entryFee, deadline, reportRaceId, sigV
        address[] calldata addressArgs, // token, uplink, bonusToken
        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        uint[] calldata bonusValue,
        bytes32 sigR,
        bytes32 sigS)
    public view returns (bool)
    {
        uint[] memory uintArgsWithoutV = new uint[](5);
        uintArgsWithoutV[0] = uintArgs[0];
        uintArgsWithoutV[1] = uintArgs[1];
        uintArgsWithoutV[2] = uintArgs[2];
        uintArgsWithoutV[3] = uintArgs[3];
        uintArgsWithoutV[4] = uintArgs[4];
        uint8 sigV;
        unchecked {
            sigV = uint8(uintArgs[5]);
        }
        bytes32 msgHash = keccak256(abi.encode(uintArgsWithoutV, addressArgs, leaderboard, bankRewards, bonusValue));
        return ecrecover(msgHash, sigV, sigR, sigS) == signerAddress;
    }

    function isValidSigReportRaceFinish(uint raceId,
        address payable[] calldata leaderboard, // players by place
        uint[] calldata bankRewards,
        IERC20Mintable bonusToken,
        uint[] calldata bonusValue,
        uint8 sigV, bytes32 sigR, bytes32 sigS)
        public view returns (bool)
    {
        bytes32 msgHash = keccak256(abi.encode(leaderboard, bankRewards, bonusToken, bonusValue));
        return ecrecover(msgHash, sigV, sigR, sigS) == signerAddress;
    }

    function isValidSigRegister(
        uint raceId,
        uint roachId,
        address token,
        uint entryFee,
        uint deadline,
        address uplink,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) public view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(raceId, roachId, token, entryFee, deadline, uplink));
        return ecrecover(msgHash, sigV, sigR, sigS) == signerAddress;
    }

    /// @notice Changes secret key that is used for signature generation
    function setSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }
}
