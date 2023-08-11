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
        uint seedBlockNumber;
    }
    mapping(address => IncubatorSlot[]) public incubators;
    mapping(uint => uint) public roachBreedCount;

    IRoachNFT public roachNtf;
    IGeneMixer public geneMixer;
    IERC20 public mutagenToken;
    IERC20 public rrcToken;
    Config public config;


    event Created(address indexed user, uint index);
    event Initiated(address indexed user, uint index, uint parent0, uint parent1, uint seedBlockNumber);
    event Egg(address indexed user, uint index, uint finishTime);
    event Available(address indexed user, uint index);
    event Roll(address indexed user, uint index, uint tryNumber, uint seedBlockNumber);

    constructor (IRoachNFT _roachNtf, IGeneMixer _geneMixer, Config _config, IERC20 _mutagenToken, IERC20 _rrcToken) {
        roachNtf = _roachNtf;
        geneMixer = _geneMixer;
        config = _config;
        mutagenToken = _mutagenToken;
        rrcToken = _rrcToken;
    }

    function buySlot() external {
        address user = msg.sender;
        _takePayments(user, config.getBuySlotPrice(user));
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
        slots.push(IncubatorSlot(IncubatorState.AVAILABLE, [uint40(0), uint40(0)], 0, 0, 0));
        slotIndex = slots.length - 1;
    }

    function init(uint index, uint40 parent0, uint40 parent1) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.AVAILABLE);
        require(roachNtf.ownerOf(parent0) == user, 'wrong parent1 owner');
        require(roachNtf.ownerOf(parent1) == user, 'wrong parent1 owner');
        require(geneMixer.canBreed(parent0, parent1), 'non compatible parents');
        require(config.isGoodBreedCount(roachBreedCount[parent0]), 'parent0 breed count limit');
        require(config.isGoodBreedCount(roachBreedCount[parent1]), 'parent0 breed count limit');

        _takePayments(user, config.getInitPrice(parent0, parent1));
        roachBreedCount[parent0]++;
        roachBreedCount[parent1]++;
        // TODO: decrease breed count

        slot.state = IncubatorState.INITIATED;
        slot.parents[0] = parent0;
        slot.parents[1] = parent1;
        slot.rollCount = 0;
        slot.seedBlockNumber = block.number;

        emit Initiated(msg.sender, index, slot.parents[0], slot.parents[1], slot.seedBlockNumber);
    }

    function start(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.INITIATED);

        _takePayments(user, config.getStartPrice(slot.parents[0], slot.parents[0]));

        slot.state = IncubatorState.EGG;
        slot.finishTime = uint40(block.timestamp + config.getRevealCooldown());

        emit Egg(msg.sender, index, slot.finishTime);
    }

    function roll(uint index) external {
        address user = msg.sender;
        IncubatorSlot storage slot = _getSlot(user, index, IncubatorState.INITIATED);

        require(slot.seedBlockNumber != block.number, 'Wait for new block');

        _takePayments(user, config.getRollPrice(slot.rollCount + 1));

        slot.rollCount++;
        slot.seedBlockNumber = block.number;

        emit Roll( user, index, slot.rollCount, slot.seedBlockNumber);
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

    function getExpectedGenome(uint40 parent0, uint40 parent1, uint seedBlockNumber) public returns (
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
            _takePayments(user, config.getSpeedupPrice(slot.finishTime - block.timestamp));
        }
        _reveal(slot, user, index);
    }

    function _takePayments(address user, uint[2] memory tokenValues) internal {
        _takePayment(user, mutagenToken, tokenValues[0]);
        _takePayment(user, rrcToken, tokenValues[1]);
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
