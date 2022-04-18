// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

interface InterfaceV2 {
    struct Bid {
        uint256 tokenId;
        uint256 bidPrice;
        address bidder;
    }

    struct Listing {
        uint256 tokenId;
        uint256 listingPrice;
        address seller;
    }

    event TokenListed(
        uint256 indexed tokenId, 
        address indexed fromAddress, 
        uint256 minValue, 
        string nft);
    event TokenDelisted(uint256 indexed tokenId, address indexed fromAddress, string nft);
    event TokenBidEntered(uint256 indexed tokenId, address indexed fromAddress, uint256 value, string nft);
    event TokenBidWithdrawn(uint256 indexed tokenId, address indexed fromAddress, uint256 value, string nft);
    event TokenBought(
        uint256 indexed tokenId,
        address indexed fromAddress,
        address indexed toAddress,
        uint256 total,
        uint256 value,
        uint256 fees,
        string nft
    );
    event TokenBidAccepted(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed bidder,
        uint256 total,
        uint256 value,
        uint256 fees,
        string nft
    );

    event TokenTransfered(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 total,
        string nft
    );

    event TokenFeeChanged(
        address nftAddress,
        string nft
    );
}