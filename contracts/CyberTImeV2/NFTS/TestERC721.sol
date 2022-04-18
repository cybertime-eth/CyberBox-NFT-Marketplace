// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TestERC721 is Ownable, ERC721Enumerable {
    constructor() public ERC721("Test ERC721", "T721") {}

    function mint() external {
        _safeMint(msg.sender, totalSupply());
    }
}