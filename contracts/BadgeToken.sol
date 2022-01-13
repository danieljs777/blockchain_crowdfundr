//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract BadgeToken is ERC721 
{
    uint256 private _tokenIds;

    constructor() ERC721("MyNFT", "MNFT") {}

    function awardBadge(address contributor) public returns (uint256)
    {
        _tokenIds++;

        _mint(contributor, _tokenIds);

        return _tokenIds;
    }
}
