// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

import "./InterfaceV2.sol";
import "./MarketPlaceFeeAPI.sol";
import "./MarketPlaceNFTAPI.sol";

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MarketPlaceV2 is InterfaceV2, MarketPlaceFeeAPI, MarketPlaceNFTAPI, OwnableUpgradeable, ReentrancyGuard, ERC1155Upgradeable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct TokenBid {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }

    bool private _isListingAndBidEnabled = true;

    mapping(uint256 => Listing) private _tokenListings;
    EnumerableSet.UintSet private _tokenIdWithListing;

    mapping(uint256 => TokenBid) private _tokenBids;
    EnumerableSet.UintSet private _tokenIdWithBid;

    EnumerableSet.AddressSet private _emptyBidders;
    uint256[] private _tempTokenIdStorage; // Storage to assist cleaning
    address[] private _tempBidderStorage; // Storage to assist cleaning bids

    constructor() public {
    }

    function initializeWithERC721(
        string memory erc721Name_,
        address _erc721Address,
        address _paymentTokenAddress,
        address _owner
    ) public initializer {
        __ERC1155_init("");
        initializeNFTWithERC721(erc721Name_, _erc721Address, _paymentTokenAddress);
        initializeFee(_owner);
        _isListingAndBidEnabled = true;
    }

    function initializeWithERC1155(
        string memory erc1155Name_,
        address _erc1155Address,
        address _paymentTokenAddress,
        address _owner
    ) public initializer {
        __ERC1155_init("");
        initializeNFTWithERC1155(erc1155Name_, _erc1155Address, _paymentTokenAddress);
        initializeFee(_owner);
        _isListingAndBidEnabled = true;
    }

    modifier onlyMarketplaceOpen() {
        require(_isListingAndBidEnabled, "Listing and bid are not enabled");
        _;
    }

    function _isListingValid(Listing memory listing) private view returns (bool) {
        if (
            _isTokenOwner(listing.tokenId, listing.seller) &&
            (_isTokenApproved(listing.tokenId) || _isAllTokenApproved(listing.seller)) &&
            listing.listingPrice > 0) {
            return true;
        }
    }
    function getTokenListing(uint256 tokenId) public view returns (Listing memory) {
        Listing memory listing = _tokenListings[tokenId];
        if (_isListingValid(listing)) {
            return listing;
        }
    }
    function getTokenListings(uint256 from, uint256 size)
        public
        view
        returns (Listing[] memory)
    {
        if (from < _tokenIdWithListing.length() && size > 0) {
            uint256 querySize = size;
            if ((from + size) > _tokenIdWithListing.length()) {
                querySize = _tokenIdWithListing.length() - from;
            }
            Listing[] memory listings = new Listing[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                Listing memory listing = _tokenListings[_tokenIdWithListing.at(i + from)];
                if (_isListingValid(listing)) {
                    listings[i] = listing;
                }
            }
            return listings;
        }
    }
    function getAllTokenListings() external view returns (Listing[] memory) {
        return getTokenListings(0, _tokenIdWithListing.length());
    }
    function _delistToken(uint256 tokenId) private {
        if (_tokenIdWithListing.contains(tokenId)) {
            delete _tokenListings[tokenId];
            _tokenIdWithListing.remove(tokenId);
        }
    }
    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     */
    function listToken(
        address sender,
        uint256 tokenId,
        uint256 value
    ) external onlyMarketplaceOpen
     returns (
        address, 
        uint256
    ) {
        require(value > 0, "Please list for more than 0 or use the transfer function");
        require(_isTokenOwner(tokenId, sender), "Only token owner can list token");
        require(
            _isTokenApproved(tokenId) || _isAllTokenApproved(sender),
            "This token is not allowed to transfer by this contract"
        );
        _tokenListings[tokenId] = Listing(tokenId, value, sender);
        _tokenIdWithListing.add(tokenId);
        return ( sender, value);
    }
    /**
     * @dev change price for already listed token.l
     
     * Must have a valid listing
     * msg.sender must not the owner of token
     */
    function changePrice(address sender,uint256 tokenId, uint256 newPrice) external nonReentrant {
        Listing memory listing = getTokenListing(tokenId); // Get valid listing
        require(_isTokenOwner(tokenId, sender), "Only token owner can change price of token");
        require(listing.seller != address(0), "Token is not for sale"); // Listing not valid
        require(
            newPrice >= 0,
            "The value send is below zero"
        );
        _tokenListings[tokenId].listingPrice = newPrice;
    }
     /**
     * @dev See {INFTKEYMarketPlaceV1-delistToken}.
     * msg.sender must be the seller of the listing record
     */
    function delistToken(address sender, uint256 tokenId) external {
        require(_tokenListings[tokenId].seller == sender, "Only token seller can delist token");
        _delistToken(tokenId);
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-buyToken}.
     * Must have a valid listing
     * msg.sender must not the owner of token
     * msg.value must be at least sell price plus fees
     */
    function buyTokenPrepare(address sender, uint256 tokenId, uint256 value) external onlyDev returns (
        address,
        address, 
        address,
        address
    ) {
        Listing memory listing = getTokenListing(tokenId); // Get valid listing
        require(listing.seller != address(0), "Token is not for sale"); // Listing not valid
        require(!_isTokenOwner(tokenId, sender), "Token owner can't buy their own token");
        require(
            value >= listing.listingPrice,
            
            "The value send is below sale price plus fees"
        );
        return (
            listing.seller,
            maketPlaceFeeAddress,
            nftCreaterAddress,
            nftProducerAddress
        );
    }
    function buyTokenComplete(address sender, uint256 tokenId) external onlyDev {


        
        Listing memory listing = getTokenListing(tokenId); // Get valid listing
         nftTransferFrom(listing.seller, sender, tokenId);
         // Remove token listing
        _delistToken(tokenId);
        _removeBidOfBidder(tokenId, sender);
    }

    /**
     * @dev Check if an bid is valid or not
     * Bidder must not be the owner
     * Bidder must give the contract allowance same or more than bid price
     * Bid price must > 0
     * Bid mustn't been expired
     */
    function _isBidValid(Bid memory bid) private view returns (bool) {
        if (
            !_isTokenOwner(bid.tokenId, bid.bidder) &&
            bid.bidPrice > 0) {
            return true;
        }
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getBidderTokenBid}.
     */
    function getBidderTokenBid(uint256 tokenId, address bidder)
        public
        view
        returns (Bid memory)
    {
        Bid memory bid = _tokenBids[tokenId].bids[bidder];
        if (_isBidValid(bid)) {
            return bid;
        }
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenBids}.
     */
    function getTokenBids(uint256 tokenId) external view returns (Bid[] memory) {
        Bid[] memory bids = new Bid[](_tokenBids[tokenId].bidders.length());
        for (uint256 i; i < _tokenBids[tokenId].bidders.length(); i++) {
            address bidder = _tokenBids[tokenId].bidders.at(i);
            Bid memory bid = _tokenBids[tokenId].bids[bidder];
            if (_isBidValid(bid)) {
                bids[i] = bid;
            }
        }
        return bids;
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenHighestBid}.
     */
    function getTokenHighestBid(uint256 tokenId) public view returns (Bid memory) {
        Bid memory highestBid = Bid(tokenId, 0, address(0));
        for (uint256 i; i < _tokenBids[tokenId].bidders.length(); i++) {
            address bidder = _tokenBids[tokenId].bidders.at(i);
            Bid memory bid = _tokenBids[tokenId].bids[bidder];
            if (_isBidValid(bid) && bid.bidPrice > highestBid.bidPrice) {
                highestBid = bid;
            }
        }
        return highestBid;
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenHighestBids}.
     */
    function getTokenHighestBids(uint256 from, uint256 size)
        public
        view
        returns (Bid[] memory)
    {
        if (from < _tokenIdWithBid.length() && size > 0) {
            uint256 querySize = size;
            if ((from + size) > _tokenIdWithBid.length()) {
                querySize = _tokenIdWithBid.length() - from;
            }
            Bid[] memory highestBids = new Bid[](querySize);
            for (uint256 i = 0; i < querySize; i++) {
                highestBids[i] = getTokenHighestBid(_tokenIdWithBid.at(i + from));
            }
            return highestBids;
        }
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getAllTokenHighestBids}.
     */
    function getAllTokenHighestBids() external view returns (Bid[] memory) {
        return getTokenHighestBids(0, _tokenIdWithBid.length());
    }

    /**
     * @dev remove a bid of a bidder
     * @param tokenId erc721 token Id
     * @param bidder bidder address
     */
    function _removeBidOfBidder(uint256 tokenId, address bidder) private {
        if (_tokenBids[tokenId].bidders.contains(bidder)) {
            // Step 1: delete the bid and the address
            delete _tokenBids[tokenId].bids[bidder];
            _tokenBids[tokenId].bidders.remove(bidder);

            // Step 2: if no bid left
            if (_tokenBids[tokenId].bidders.length() == 0) {
                _tokenIdWithBid.remove(tokenId);
            }
        }
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-enterBidForToken}.
     * People can only enter bid if bid is allowed
     * The timestamp set needs to be in the allowed range
     * bid price > 0
     * must not be token owner
     * must allow this contract to spend enough payment token
     */
    function enterBidForToken(
        address sender,
        uint256 tokenId,
        uint256 bidPrice
    ) external onlyMarketplaceOpen {
        require(bidPrice > 0, "Please bid for more than 0");
        require(!_isTokenOwner(tokenId, sender), "This Token belongs to this address");
      
        Bid memory bid = Bid(tokenId, bidPrice, sender);
        if (!_tokenIdWithBid.contains(tokenId)) {
            _tokenIdWithBid.add(tokenId);
        }
        _tokenBids[tokenId].bidders.add(sender);
        _tokenBids[tokenId].bids[sender] = bid;
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-acceptBidForToken}.
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches the bidder address
     */
     /**
     * @dev See {INFTKEYMarketPlaceV1-withdrawBidForToken}.
     * There must be a bid exists
     * remove this bid record
     */
    function withdrawBidForToken(address sender, uint256 tokenId) external returns (address, uint256 bidPrice) {
        Bid memory bid = _tokenBids[tokenId].bids[sender];
        require(bid.bidder == sender, "This address doesn't have bid on this token");
        _removeBidOfBidder(tokenId, sender);
        return (bid.bidder, bid.bidPrice);
    }
    function acceptBidForTokenPrepare(address sender, uint256 tokenId, address bidder) external  onlyDev returns (
        address, 
        address,
        address,
        uint256
    ) {
        require(_isTokenOwner(tokenId, sender), "Only token owner can accept bid of token");
        require(
            _isTokenApproved(tokenId) || _isAllTokenApproved(sender),
            "The token is not approved to transfer by the contract"
        );

        Bid memory existingBid = getBidderTokenBid(tokenId, bidder);
        require(
            existingBid.bidPrice > 0 && existingBid.bidder == bidder,
            "This token doesn't have a matching bid"
        );
        return (
            maketPlaceFeeAddress,
            nftCreaterAddress,
            nftProducerAddress,
            existingBid.bidPrice
        );
    }
    function acceptBidForTokenComplete(address sender, uint256 tokenId, address bidder) external  onlyDev{
        nftTransferFrom(sender, bidder, tokenId);
        // Remove token listing
        _delistToken(tokenId);
        _removeBidOfBidder(tokenId, bidder);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-getInvalidListingCount}.
     */
    function getInvalidListingCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIdWithListing.length(); i++) {
            if (!_isListingValid(_tokenListings[_tokenIdWithListing.at(i)])) {
                count = count.add(1);
            }
        }
        return count;
    }

    /**
     * @dev Count how many bid records of a token are invalid now
     */
    function _getInvalidBidOfTokenCount(uint256 tokenId) private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenBids[tokenId].bidders.length(); i++) {
            address bidder = _tokenBids[tokenId].bidders.at(i);
            Bid memory bid = _tokenBids[tokenId].bids[bidder];
            if (!_isBidValid(bid)) {
                count = count.add(1);
            }
        }
        return count;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-getInvalidBidCount}.
     */
    function getInvalidBidCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIdWithBid.length(); i++) {
            count = count.add(_getInvalidBidOfTokenCount(_tokenIdWithBid.at(i)));
        }
        return count;
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidListings}.
     */
    function cleanAllInvalidListings() external returns(uint256[] memory){
        for (uint256 i = 0; i < _tokenIdWithListing.length(); i++) {
            uint256 tokenId = _tokenIdWithListing.at(i);
            if (!_isListingValid(_tokenListings[tokenId])) {
                _tempTokenIdStorage.push(tokenId);
            }
        }
        for (uint256 i = 0; i < _tempTokenIdStorage.length; i++) {
            _delistToken(_tempTokenIdStorage[i]);
        }
        
        return (_tempTokenIdStorage);
    }

    function deleteTempTokenIdStorage() external onlyDev {
        delete _tempTokenIdStorage;
    }

    /**
     * @dev remove invalid bids of a token
     * @param tokenId erc721 token Id
     */
    function _cleanInvalidBidsOfToken(uint256 tokenId) private {
        for (uint256 i = 0; i < _tokenBids[tokenId].bidders.length(); i++) {
            address bidder = _tokenBids[tokenId].bidders.at(i);
            Bid memory bid = _tokenBids[tokenId].bids[bidder];
            if (!_isBidValid(bid)) {
                _tempBidderStorage.push(_tokenBids[tokenId].bidders.at(i));
            }
        }
        for (uint256 i = 0; i < _tempBidderStorage.length; i++) {
            address bidder = _tempBidderStorage[i];
            _removeBidOfBidder(tokenId, bidder);
        }
        delete _tempBidderStorage;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidBids}.
     */
    function cleanAllInvalidBids() external returns(uint256[] memory){
        for (uint256 i = 0; i < _tokenIdWithBid.length(); i++) {
            uint256 tokenId = _tokenIdWithBid.at(i);
            uint256 invalidCount = _getInvalidBidOfTokenCount(tokenId);
            if (invalidCount > 0) {
                _tempTokenIdStorage.push(tokenId);
            }
        }
        for (uint256 i = 0; i < _tempTokenIdStorage.length; i++) {
            _cleanInvalidBidsOfToken(_tempTokenIdStorage[i]);
        }
        return (_tempTokenIdStorage);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-isListingAndBidEnabled}.
     */
    function isListingAndBidEnabled() external view returns (bool) {
        return _isListingAndBidEnabled;
    }
    /**
     * @dev Enable to disable Bids and Listing
     */
    function changeMarketplaceStatus(bool enabled) external onlyDev {
        _isListingAndBidEnabled = enabled;
    }
    
}