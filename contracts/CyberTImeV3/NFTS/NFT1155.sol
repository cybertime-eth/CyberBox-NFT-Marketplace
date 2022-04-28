// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract NFT1155 is Context, ERC1155 {
    constructor(string memory uri) ERC1155(uri) public {
    }
    function mint(address owner, uint256 nftId, uint256 amount) public {
        _mint(owner, nftId, amount, "");
    }
}