// SPDX-License-Identifier: MIT
// Roach Racing Club: Collectible NFT game (https://roachracingclub.com/)
pragma solidity ^0.8.10;

/// @title Roach Racing Club NFT registry interface
interface IRoachNFT {

    /// @notice Mints new token with autoincremented index and stores traitBonus/syndicate for reveal
    function mintGen0(address to, uint count, uint8 traitBonus, string calldata syndicate) external;

    /// @notice lastRoachId doesn't equap totalSupply because some token will be burned
    ///         in using Run or Die mechanic
    function lastRoachId() external view returns (uint);

    /// @notice Total number of minted tokens for account
    function getNumberMinted(address account) external view returns (uint64);

}
