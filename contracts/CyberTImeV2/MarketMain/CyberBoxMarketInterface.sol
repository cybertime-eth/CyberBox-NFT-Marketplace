// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

interface CyberBoxMarketInterface {
    event CyberMarketTokenAdded(
        string nftName, 
        string nftSymbol,  
        address nftAddress, 
        string erc20Name,
        string erc20Symbol,
        address erc20Address,
        address marketPlaceAddress
    );

    event CyberMarketTokenChanged(
        address nftAddress, 
        string erc20Name,
        string erc20Symbol,
        address erc20Address,
        address marketPlaceAddress
    );

    event CyberMarketFeeChanged(
        address nftAddress,
        uint256 createrFee,
        uint256 producerFee
    );
    event CyberMarketDevFeeChanged(
        address nftAddress,
        address marketPlaceFeeAddress,
        uint256 marketFee
    );
    event CyberMarketTokenCreaterChanged(
        address nftAddress,
        address tokenCreaterAddress
    );
    event CyberMarketTokenProducerChanged(
        address nftAddress,
        address tokenCreaterAddress
    );
    event CyberMarketTokenBought(
        address nftAddress,
        uint256 tokenId,
        address fromAddress, 
        address toAddress,
        uint256 total,
        uint256 value,
        uint256 fees
    );
    event CyberMarketTokenListed(
        address nftAddress,
        uint256 indexed tokenId, 
        address indexed fromAddress, 
        uint256 minValue
    );
    event CyberMarketTokenDelisted(
        address nftAddress,
        uint256 indexed tokenId
    );
    event CyberMarketCleanList(
        address nftAddress,
        uint256 tokenId
    );
    event CyberMarketTokenTransfered(
        address nftAddress,
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 total
    );

    event CyberMarketTokenBidEntered(
        address nftAddress,
        uint256 indexed tokenId, 
        address indexed fromAddress, 
        uint256 value
    );
    event CyberMarketTokenBidWithdrawn(
        address nftAddress,
        uint256 indexed tokenId, 
        address indexed fromAddress
    );
    event CyberMarketTokenBidAccepted(
        address nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        address indexed bidder,
        uint256 total,
        uint256 value,
        uint256 fees
    );
    event CyberMarketCleanBid(
        address nftAddress,
        uint256 tokenId
    );

    event CyberMarketTokenPriceChanged(
        address nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

}