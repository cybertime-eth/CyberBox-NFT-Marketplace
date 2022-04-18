// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;


interface CyberBoxManagerInterface {
    event CyberBoxManagerDelisted(
        address nftAddress,
        uint256 indexed tokenId
    );
}