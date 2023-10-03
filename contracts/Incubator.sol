// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.18;

import "./Operators.sol";
import "../interfaces/IRoachNFT.sol";
import "../interfaces/iGeneMixer.sol";
import "OpenZeppelin/openzeppelin-contracts@4.8.3/contracts/token/ERC20/IERC20.sol";
import "./Config.sol";

contract Incubator is Operators {

    enum IncubatorState {
        AVAILABLE,
        INITIATED,
        EGG
    }

    struct IncubatorSlot {
        IncubatorState state;
        uint40[2] parents;
        uint16 rollCount;
        uint40 finishTime;
        uint40 seedBlockNumber;
        uint40 initCount;
    }
    mapping(address => IncubatorSlot[]) public incubators;

    IRoachNFT public roachNtf;
    IGeneMixer public geneMixer;
    IERC20 public mutagenToken;
    IERC20 public rrcToken;
    Config public config;


    event Created(address indexed user, uint index);
    event Initiated(address indexed user, uint index, uint parent0, uint parent1, uint seedBlockNumber);
    event Egg(address indexed user, uint index, uint finishTime);
    event Available(address indexed user, uint index);
    event Roll(address indexed user, uint index, uint rollNumber, uint seedBlockNumber);

    constructor (IRoachNFT _roachNtf, IGeneMixer _geneMixer, Config _config, IERC20 _mutagenToken, IERC20 _rrcToken) {
        roachNtf = _roachNtf;
        geneMixer = _geneMixer;
        config = _config;
        mutagenToken = _mutagenToken;
        rrcToken = _rrcToken;
    }

    function buySlot() external {
        address user = msg.sender;
        (address tokenAddress, uint tokenValue) = config.getBuySlotPrice(user);
        _takePayment(user, tokenAddress, tokenValue);
        uint index = _addSlot(user);
        emit Created(user, index);
    }

    function unlockSlot(uint sigv) external {
        // TODO: check signature
        address user = msg.sender;
        uint index = _addSlot(user);
        emit Created(user, index);
    }

    function _addSlot(address user) private returns (uint slotIndex) {
        IncubatorSlot[] storage slots = incubators[user];
        slots.push(IncubatorSlot(IncubatorState.AVAILABLE, [uint40(0), uint40(0)], 0, 0, 0, 0));
        slotIndex = slots.length - 1;
    }

    function init(uint index, uint40 parent0, uint40 parent1) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.AVAILABLE);
        require(roachNtf.ownerOf(parent0) == user, 'wrong parent1 owner');
        require(roachNtf.ownerOf(parent1) == user, 'wrong parent1 owner');
        require(geneMixer.canBreed(parent0, parent1), 'non compatible parents');
        require(config.isGoodBreedCount(roachNtf.getBreedCount(parent0)), 'parent0 breed count limit');
        require(config.isGoodBreedCount(roachNtf.getBreedCount(parent1)), 'parent1 breed count limit');

        (address tokenAddress, uint tokenValue) = config.getInitPrice(parent0, parent1);
        _takePayment(user, tokenAddress, tokenValue);

        roachNtf.incBreedCount(parent0);
        roachNtf.incBreedCount(parent1);

        slot.state = IncubatorState.INITIATED;
        slot.parents[0] = parent0;
        slot.parents[1] = parent1;
        slot.rollCount = 0;
        slot.initCount++;
        slot.seedBlockNumber = uint40(block.number);

        emit Initiated(msg.sender, index, slot.parents[0], slot.parents[1], slot.seedBlockNumber);
    }

    function start(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.INITIATED);

        (address tokenAddress, uint tokenValue) = config.getStartPrice(slot.parents[0], slot.parents[0]);
        _takePayment(user, tokenAddress, tokenValue);

        slot.state = IncubatorState.EGG;
        slot.finishTime = uint40(block.timestamp + config.getRevealCooldown());

        emit Egg(msg.sender, index, slot.finishTime);
    }

    function _isCalledFromContract() view internal returns (bool) {
        return tx.origin != msg.sender;
    }

    function roll(uint index) external {
        require(!_isCalledFromContract(), "Called from another contract");

        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.INITIATED);

        require(slot.seedBlockNumber != block.number, 'Wait for new block');

        (address tokenAddress, uint tokenValue) = config.getRollPrice(slot.rollCount + 1);
        _takePayment(user, tokenAddress, tokenValue);

        slot.rollCount++;
        slot.seedBlockNumber = uint40(block.number);

        uint probability = config.getBreedSuccessProbability(slot.rollCount);
        // TODO: good random
        uint randomValue = uint(keccak256(abi.encodePacked(blockhash(block.number - 1))));
        uint dice = randomValue % 100;
        if (dice < probability) {
            emit Roll(user, index, slot.rollCount, slot.seedBlockNumber);
        } else {
            _resetSlot(slot, user, index);
        }
    }

    function _getSlot(address user, uint index, IncubatorState state) private view returns (IncubatorSlot storage) {
        IncubatorSlot[] storage slots = incubators[user];
        require(index < slots.length, 'Wrong slot');
        IncubatorSlot storage slot = slots[index];
        require(slot.state == state, 'Wrong slot state');
        return slot;
    }

    function cancel(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.INITIATED);

        _resetSlot(slot, user, index);
    }

    function _resetSlot(IncubatorSlot storage slot, address user, uint index) private {
        slot.state = IncubatorState.AVAILABLE;
        emit Available(user, index);
    }

    function _reveal(IncubatorSlot storage slot, address user, uint index) private {
        bytes memory genome;
        uint40 generation;
        uint16 resistance;
        (genome, generation, resistance) = getExpectedGenome(slot.parents[0], slot.parents[1], slot.seedBlockNumber);

        roachNtf.mint(user, genome, slot.parents, generation, resistance);
        _resetSlot(slot, user, index);
    }

    function getExpectedGenome(uint40 parent0, uint40 parent1, uint seedBlockNumber) public view returns (
        bytes memory genome,
        uint40 generation,
        uint16 resistance
    ) {
        require(block.number > seedBlockNumber, 'Wait for block');
        uint seed = uint(keccak256(abi.encodePacked(blockhash(seedBlockNumber))));
        (genome, generation, resistance) = geneMixer.calculateGenome(parent0, parent1, seed);
    }

    function reveal(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.EGG);
        require(slot.finishTime <= block.timestamp, 'Cooldown in progress');

        _reveal(slot, user, index);
    }

    function speedup(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.EGG);
        if (block.timestamp < slot.finishTime) {
            (address tokenAddress, uint tokenValue) = config.getSpeedupPrice(slot.finishTime - block.timestamp);
            _takePayment(user, tokenAddress, tokenValue);
        }
        _reveal(slot, user, index);
    }


    function _takePayment(address user, address priceToken, uint priceValue) internal {
        if (priceValue > 0) {
            IERC20(priceToken).transferFrom(
                user,
                address(this),
                priceValue
            );
        }
    }

}
