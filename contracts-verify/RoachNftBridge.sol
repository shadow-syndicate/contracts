// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.19;

import {CCIPReceiver} from "CCIPReceiver.sol";
import {IRouterClient} from "IRouterClient.sol";
import {Client} from "Client.sol";
import "IRoachNFT.sol";
import "Operators.sol";

contract RoachNftBridge is CCIPReceiver, Operators {

    event Sent(uint tokenId, bytes32 messageId);
    event Receive(uint tokenId, bytes32 messageId);

    IRouterClient public router;
    IRoachNFT public nftContract;
    mapping(uint64 => address) public destinationContract; // chainSelector -> contract address


    constructor(IRoachNFT _nftContract, address _routerAddress)
    CCIPReceiver (_routerAddress)
    {
        nftContract = _nftContract;
        router = IRouterClient(_routerAddress);
    }

    function setDestination(uint64 chainSelector, address contractAddress) external onlyOperator {
        destinationContract[chainSelector] = contractAddress;
    }

    function _getRoachBridgeData(uint tokenId) view internal returns (bytes memory data) {
        (
            bytes memory genome,
            uint40[2] memory parents,
            uint40 creationTime,
            uint40 revealTime,
            uint40 generation,
            uint16 resistance,
            uint16 breedCount,
            string memory name,
            address owner) = nftContract.getRoach(tokenId);

        return abi.encode(owner, tokenId, genome, parents, generation, resistance);
    }

    function getTargetContractAddress(uint64 destinationChainSelector)
    view public returns (address target) {
        return destinationContract[destinationChainSelector];
    }

    function _getRoachBridgeMessage(uint tokenId, uint64 destinationChainSelector)
    view internal returns (Client.EVM2AnyMessage memory message) {
        (
            bytes memory genome,
            uint40[2] memory parents,
            uint40 creationTime,
            uint40 revealTime,
            uint40 generation,
            uint16 resistance,
            uint16 breedCount,
            string memory name,
            address owner) = nftContract.getRoach(tokenId);

        bytes memory data = _getRoachBridgeData(tokenId);

        address receiver = getTargetContractAddress(destinationChainSelector);
        return Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
    }

    function getFee(uint tokenId, uint64 destinationChainSelector) external view returns (uint256) {
        return _getFee(_getRoachBridgeMessage(tokenId, destinationChainSelector), destinationChainSelector);
    }

    function _getFee(Client.EVM2AnyMessage memory message, uint64 destinationChainSelector) internal view returns (uint256) {
        return router.getFee(
            destinationChainSelector,
            message
        );
    }

    // https://docs.chain.link/ccip/supported-networks/
    function sendRoach(uint tokenId, uint64 destinationChainSelector) external payable {
        require(nftContract.ownerOf(tokenId) == msg.sender, 'Access denied');

        Client.EVM2AnyMessage memory message = _getRoachBridgeMessage(tokenId, destinationChainSelector);

        uint256 fee = _getFee(message, destinationChainSelector);

        require(msg.value >= fee, 'Payment required');


        nftContract.burnFrom(tokenId);

        bytes32 messageId = router.ccipSend{value: fee}(
            destinationChainSelector,
            message
        );

        emit Sent(tokenId, messageId);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (
            address owner,
            uint tokenId,
            bytes memory genome,
            uint40[2] memory parents,
            uint40 generation,
            uint16 resistance
        ) = abi.decode(message.data, (address, uint, bytes, uint40[2], uint40, uint16));
        nftContract.revive(owner, tokenId);
        emit Receive(tokenId, message.messageId);
    }
}
