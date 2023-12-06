// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

/*
.................................,,:::,...........
..............................,:;;;:::;;;,........
...............,,,,,.........:;;,......,;+:.......
.............:::,,,::,.....,+;,..........:*;......
...........,;:.......,:,..,+:.............:*:.....
..........:;,..........:,.+:...............*+.....
.........,+,..........,,:;+,,,.............;*,....
.........+:.......,:+?SS####SS%*;,.........;*:....
........:+.....,;?S##############S?:.......;*,....
........;+....;?###############%??##+......+*,....
........:+...,%SS?;?#########@@S?++S#:....,+;.....
........,+:..,%S%*,*#####SSSSSS%*;,%S,............
.........;;,..;SS%S#####SSSS%%%?+:*%;.............
..........,....:%########SSS%%?*?%?,..............
.............,,,.+S##@#?+;;*%%SS%;................
.........,,.,+++;:+%##?+*+:,?##S+;:,..............
....,,;+*SS*??***++?S#S?*+:,%S%%%%%?+:,......,....
,:;**???*?#@##S?***++*%%*;,:%%%%**?%%?;,,.,;?%?%??
????*+;:,,*####S%%?*+;:;;,,+#S%%%?*?%??+;*%S?*%SSS
*+;:,....,%@S####SS%?*+:::*S@#%%%%????%%S%*;::,,,:
.........+@@S%S####S#@%?%%SS#@SS%%%%SS%*++;,......
........,%@@S%%S#@##@#%%%%%%S@##SSS%*+*?%?;,......
........:#@@%%%%%S@S##%%%%%%%#@##?++**%%S%+:......
........+@@#%SS%%%SSS?S%%%%%%S@SS?????%?S%*;,.....
........?@@@%%%%%%%%%%%%%%%%%%%%%%??**?%#%%;,.....
*/

/// @title Roach Racing Club NFT registry interface
interface IRoach {

    /// @notice Mints new token with autoincremented index
    function mintGen0(address to, uint count) external;

    function mint(
        address to,
        bytes calldata genome,
        uint40[2] calldata parents,
        uint40 generation,
        uint16 resistance
    ) external;

    /// @notice lastRoachId doesn't equal totalSupply because some token will be burned
    ///         in using Run or Die mechanic
    function lastRoachId() external view returns (uint);

    /// @notice Total number of minted tokens for account
    function getNumberMinted(address account) external view returns (uint64);

    function canReveal(uint tokenId) external view returns (bool);
    function revealOperator(uint tokenId, bytes calldata genome) external;

    // function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Returns contract level metadata for roach
    /// @return genome       Array of genes in secret format
    /// @return generation   Gen0, Gen1, etc
    /// @return resistance   Resistance percentage (1234 = 12.34%)
    function getRoachShort(uint roachId) external view
        returns (
            bytes memory genome,
            uint40 generation,
            uint16 resistance);

    function getRoach(uint roachId) external view
    returns (
        bytes memory genome,
        uint40[2] memory parents,
        uint40 creationTime,
        uint40 revealTime,
        uint40 generation,
        uint16 resistance,
        uint16 breedCount,
        string memory name,
        address owner);

    function getBreedCount(uint roachId) external view returns (uint16 breedCount);
    function incBreedCount(uint tokenId) external;

    function revive(
        address to,
        uint tokenId
    ) external;

    function burnFrom(uint tokenId) external;
    // function transferFrom(address from, address to, uint256 tokenId) external;
    function lock(uint tokenId) external;
    function lockOperator(uint tokenId) external;
    function unlock(uint tokenId) external;
    function isLocked(uint tokenId) external view returns (bool);
}
