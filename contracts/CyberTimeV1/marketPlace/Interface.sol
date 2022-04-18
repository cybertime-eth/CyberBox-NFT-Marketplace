// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

interface Interface {
    struct Bid {
        uint256 tokenId;
        uint256 bidPrice;
        address bidder;
        uint256 expireTimestamp;
    }

    struct Listing {
        uint256 tokenId;
        uint256 listingPrice;
        address seller;
        uint256 expireTimestamp;
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

    /**
     * @dev surface the erc721 token contract address
     */
    function tokenAddress() external view returns (address);

    /**
     * @dev surface the erc20 payment token contract addres
     s
     */
    function paymentTokenAddress() external view returns (address);

    /**
     * @dev get current listing of a token
     * @param tokenId erc721 token Id
     * @return current valid listing or empty listing struct
     */
    function getTokenListing(uint256 tokenId) external view returns (Listing memory);

    /**
     * @dev get current valid listings by size
     * @param from index to start
     * @param size size to query
     * @return current valid listings
     * This to help batch query when list gets big
     */
    function getTokenListings(uint256 from, uint256 size) external view returns (Listing[] memory);

    /**
     * @dev get all current valid listings
     * @return current valid listings
     */
    function getAllTokenListings() external view returns (Listing[] memory);

    /**
     * @dev get bidder's bid on a token
     * @param tokenId erc721 token Id
     * @param bidder address of a bidder
     * @return Valid bid or empty bid
     */
    function getBidderTokenBid(uint256 tokenId, address bidder) external view returns (Bid memory);

    /**
     * @dev get all valid bids of a token
     * @param tokenId erc721 token Id
     * @return Valid bids of a token
     */
    function getTokenBids(uint256 tokenId) external view returns (Bid[] memory);

    /**
     * @dev get highest bid of a token
     * @param tokenId erc721 token Id
     * @return Valid highest bid or empty bid
     */
    function getTokenHighestBid(uint256 tokenId) external view returns (Bid memory);

    /**
     * @dev get current highest bids
     * @param from index to start
     * @param size size to query
     * @return current highest bids
     * This to help batch query when list gets big
     */
    function getTokenHighestBids(uint256 from, uint256 size) external view returns (Bid[] memory);

    /**
     * @dev get all highest bids
     * @return All valid highest bids
     */
    function getAllTokenHighestBids() external view returns (Bid[] memory);

    /**
     * @dev Count how many listing records are invalid now
     * This is to help admin to decide to do a cleaning or not
     */
    function getInvalidListingCount() external view returns (uint256);

    /**
     * @dev Count how many bids records are invalid now
     * This is to help admin to decide to do a cleaning or not
     */
    function getInvalidBidCount() external view returns (uint256);

    /**
     * @dev Name of ERC721 token
     */
    function erc721Name() external view returns (string memory);

    /**
     * @dev Show if listing and bid are enabled
     */
    function isListingAndBidEnabled() external view returns (bool);

    /**
     * @dev Surface minimum listing and bid time range
     */
    function actionTimeOutRangeMin() external view returns (uint256);

    /**
     * @dev Surface maximum listing and bid time range
     */
    function actionTimeOutRangeMax() external view returns (uint256);

    /**
     * @dev Service fee
     * @return fee fraction and fee base
     */
    function serviceFee(address nftAddress) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);
}