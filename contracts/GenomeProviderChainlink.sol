// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

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

import "./GenomeProviderPolygon.sol";
import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "smartcontractkit/chainlink@2.7.0/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

/// @title Genome generator
/// @author Shadow Syndicate / Andrey Pelipenko
/// @dev Production version of GenomeProvider that used real Chainlink VRF
contract GenomeProviderChainlink is GenomeProviderPolygon, VRFConsumerBaseV2 {
    bytes32 chainLinkKeyHash;
    uint256 public chainLinkFee;
    uint64 subscriptionId;
    VRFCoordinatorV2Interface vrfCoordinator;
    uint32 constant callbackGasLimit = 2_000_000;
    uint16 constant requestConfirmations = 3;
    mapping(uint => uint) public requests;

    // Chainlink constants: https://docs.chain.link/docs/vrf-contracts/
    constructor(
        address _vrfCoordinator,
        bytes32 _chainLinkKeyHash,
        uint64 _subscriptionId
    )
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkKeyHash = _chainLinkKeyHash;
        subscriptionId = _subscriptionId;
    }

    function _requestRandomness(uint tokenId) internal override {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            chainLinkKeyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1);
        requests[requestId] = tokenId;
    }

    /// @notice ChainlinkVRF callback function with supplied randomness
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint tokenId = requests[requestId];
        delete requests[requestId];
        _onRandomnessArrived(tokenId, randomWords[0]);
    }
}
