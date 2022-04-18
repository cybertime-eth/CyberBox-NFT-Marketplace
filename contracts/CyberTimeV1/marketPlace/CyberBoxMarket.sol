// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
/**
 * @title NFTKEY MarketPlace contract V1
 * Note: This marketplace contract is collection based. It serves one ERC721 contract only
 * Payment tokens usually is the chain native coin's wrapped token, e.g. WETH, WBNB
 */
contract CyberBoxMarket is Interface, OwnableUpgradeable, ReentrancyGuard, ERC1155Upgradeable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public dev; // developer address

    struct TokenBid {
        EnumerableSet.AddressSet bidders;
        mapping(address => Bid) bids;
    }

    string private _erc721Name;
    IERC721 private _erc721;
    address private _selectedNftAddress;
    address private _selectedERC20Address;
    IERC20 private _paymentToken;

    bool private _isListingAndBidEnabled = true;

    uint256 private _baseFeeTokenSeller = 0;
    uint256 private _baseFeeTokenProducer = 0;
    uint256 private _baseFeeTokenCreater = 0;
    uint256 private _baseFeeTokenDev = 0;
    uint256 private _baseFeeFraction = 0;
    uint256 private _baseFeeTokenBase = 0;

    mapping(address => address) private _erc20Manager;

    address public maketPlaceFeeAddress;
    address public nftCreaterAddress;
    address public nftProducerAddress;

    uint256 private _actionTimeOutRangeMin = 86400; // 24 hours
    uint256 private _actionTimeOutRangeMax = 31536000; // One year - This can extend by owner is contract is working smoothly

    mapping(uint256 => Listing) private _tokenListings;
    EnumerableSet.UintSet private _tokenIdWithListing;

    mapping(uint256 => TokenBid) private _tokenBids;
    EnumerableSet.UintSet private _tokenIdWithBid;

    
    // uint8 public partnerSharePercentage = 0;
    // bool public hasSharePercentageProposal;
    // uint8 public partnerSharePercentageProposal;

    EnumerableSet.AddressSet private _emptyBidders; // Help initiate TokenBid struct
    uint256[] private _tempTokenIdStorage; // Storage to assist cleaning
    address[] private _tempBidderStorage; // Storage to assist cleaning bids

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }

    constructor() public {

    }

    function initialize(
        string memory erc721Name_,
        address _erc721Address,
        address _paymentTokenAddress,
        address _owner
    ) public initializer {
        __ERC1155_init("");
        _erc721Name = erc721Name_;
        _erc721 = IERC721(_erc721Address);
        _selectedNftAddress = _erc721Address;
        _paymentToken = IERC20(_paymentTokenAddress);
        _erc20Manager[_erc721Address] = _paymentTokenAddress;
        _selectedERC20Address = _paymentTokenAddress;
        
        _isListingAndBidEnabled = true;
        
        _baseFeeTokenSeller = 975;
        _baseFeeTokenProducer = 0;
        _baseFeeTokenCreater = 0;
        _baseFeeTokenDev = 25;
        _baseFeeFraction = 25;
        _baseFeeTokenBase = 1000;

        _actionTimeOutRangeMin = 86400;
        _actionTimeOutRangeMax = 31536000;

        dev = msg.sender;
        maketPlaceFeeAddress = _owner;
    }


    /**
     * @dev only if listing and bid is enabled
     * This is to help contract migration in case of upgrade or bug
     */
    modifier onlyMarketplaceOpen() {
        require(_isListingAndBidEnabled, "Listing and bid are not enabled");
        _;
    }

    /**
     * @dev only if the entered timestamp is within the allowed range
     * This helps to not list or bid for too short or too long period of time
     */
    modifier onlyAllowedExpireTimestamp(uint256 expireTimestamp) {
        require(
            expireTimestamp.sub(block.timestamp) >= _actionTimeOutRangeMin,
            "Please enter a longer period of time"
        );
        require(
            expireTimestamp.sub(block.timestamp) <= _actionTimeOutRangeMax,
            "Please enter a shorter period of time"
        );
        _;
    }

    /**
     * @dev check if the account is the owner of this erc721 token
     */
    function _isTokenOwner(uint256 tokenId, address account) private view returns (bool) {
        try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
            return tokenOwner == account;
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function _isTokenApproved(uint256 tokenId) private view returns (bool) {
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function _isAllTokenApproved(address owner) private view returns (bool) {
        return _erc721.isApprovedForAll(owner, address(this));
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-tokenAddress}.
     */
    function tokenAddress() external view override returns (address) {
        return address(_erc721);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-paymentTokenAddress}.
     */
    function paymentTokenAddress() external view override returns (address) {
        return address(_paymentToken);
    }

    /**
     * @dev Check if a listing is valid or not
     * The seller must be the owner
     * The seller must have give this contract allowance
     * The sell price must be more than 0
     * The listing mustn't be expired
     */
    function _isListingValid(Listing memory listing) private view returns (bool) {
        if (
            _isTokenOwner(listing.tokenId, listing.seller) &&
            (_isTokenApproved(listing.tokenId) || _isAllTokenApproved(listing.seller)) &&
            listing.listingPrice > 0 &&
            listing.expireTimestamp > block.timestamp
        ) {
            return true;
        }
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenListing}.
     */
    function getTokenListing(uint256 tokenId) public view override returns (Listing memory) {
        Listing memory listing = _tokenListings[tokenId];
        if (_isListingValid(listing)) {
            return listing;
        }
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenListings}.
     */
    function getTokenListings(uint256 from, uint256 size)
        public
        view

        override
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

    /**
     * @dev See {INFTKEYMarketPlaceV1-getAllTokenListings}.
     */
    function getAllTokenListings() external view override returns (Listing[] memory) {
        return getTokenListings(0, _tokenIdWithListing.length());
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
            bid.bidPrice > 0 &&
            bid.expireTimestamp > block.timestamp
        ) {
            return true;
        }
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-getBidderTokenBid}.
     */
    function getBidderTokenBid(uint256 tokenId, address bidder)
        public
        view
        override
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
    function getTokenBids(uint256 tokenId) external view override returns (Bid[] memory) {
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
    function getTokenHighestBid(uint256 tokenId) public view override returns (Bid memory) {
        Bid memory highestBid = Bid(tokenId, 0, address(0), 0);
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
        override
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
    function getAllTokenHighestBids() external view override returns (Bid[] memory) {
        return getTokenHighestBids(0, _tokenIdWithBid.length());
    }

    /**
     * @dev delist a token - remove token id record and remove listing from mapping
     * @param tokenId erc721 token Id
     */
    function _delistToken(uint256 tokenId) private {
        if (_tokenIdWithListing.contains(tokenId)) {
            delete _tokenListings[tokenId];
            _tokenIdWithListing.remove(tokenId);
        }
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
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     * @param expireTimestamp when would this listing expire
     */
    function listToken(
        address sender,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
    ) external onlyMarketplaceOpen onlyAllowedExpireTimestamp(expireTimestamp)
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

        _tokenListings[tokenId] = Listing(tokenId, value, sender, expireTimestamp);
        _tokenIdWithListing.add(tokenId);

        emit TokenListed(tokenId, sender, value, _erc721Name);
        return ( sender, value);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-delistToken}.
     * msg.sender must be the seller of the listing record
     */
    function delistToken(address sender, uint256 tokenId) external {
        require(_tokenListings[tokenId].seller == sender, "Only token seller can delist token");
        emit TokenDelisted(tokenId, _tokenListings[tokenId].seller, _erc721Name);
        _delistToken(tokenId);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-acceptBidForToken}.
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches the bidder address
     */
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
        _erc721.safeTransferFrom(sender, bidder, tokenId);
        // Remove token listing
        _delistToken(tokenId);
        _removeBidOfBidder(tokenId, bidder);
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

    function calculateSellerFee(uint256 value) public returns(uint256){
        return value.sub(value.mul(_baseFeeFraction).div(_baseFeeTokenBase));
    }
    function calculateDevFee(uint256 value) public returns(uint256){
        return value.mul(_baseFeeTokenDev).div(_baseFeeTokenBase);
    }
    function calculateCreaterFee(uint256 value) public returns(uint256){
        return value.mul(_baseFeeTokenCreater).div(_baseFeeTokenBase);
    }
    function calculateProducerFee(uint256 value) public returns(uint256){
        return value.mul(_baseFeeTokenProducer).div(_baseFeeTokenBase);
    }

    function buyTokenComplete(address sender, uint256 tokenId) external onlyDev {
        Listing memory listing = getTokenListing(tokenId); // Get valid listing
         _erc721.safeTransferFrom(listing.seller, sender, tokenId);
         // Remove token listing
        _delistToken(tokenId);
        _removeBidOfBidder(tokenId, sender);
    }

    /**
     * @dev change price for already listed token.
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
     * @dev Transfer token to Other
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches the bidder address
    */
    function transfer(
        address sender,
        address to,
        uint256 tokenId
    ) external onlyDev {
        require(_isTokenOwner(tokenId, sender), "Only token owner can accept bid of token");
        require(
            _isTokenApproved(tokenId) || _isAllTokenApproved(sender),
            "The token is not approved to transfer by the contract"
        );
        _erc721.safeTransferFrom(sender, to, tokenId);
        
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
        uint256 bidPrice,
        uint256 expireTimestamp
    ) external onlyMarketplaceOpen onlyAllowedExpireTimestamp(expireTimestamp) {
        require(bidPrice > 0, "Please bid for more than 0");
        require(!_isTokenOwner(tokenId, sender), "This Token belongs to this address");
        // require(
        //     _paymentToken.allowance(msg.sender, address(this)) >= bidPrice,
        //     "Need to have enough token holding to bid on this token"
        // );

        Bid memory bid = Bid(tokenId, bidPrice, sender, expireTimestamp);

        // if no bids of this token add a entry to both records _tokenIdWithBid and _tokenBids
        if (!_tokenIdWithBid.contains(tokenId)) {
            _tokenIdWithBid.add(tokenId);
            // _tokenBids[tokenId] = TokenBid(_emptyBidders);
        }

        _tokenBids[tokenId].bidders.add(sender);
        console.log("bidders count", _tokenBids[tokenId].bidders.length());
        _tokenBids[tokenId].bids[sender] = bid;
        console.log("bid", bid.bidder);

        emit TokenBidEntered(tokenId, sender, bidPrice, _erc721Name);
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-withdrawBidForToken}.
     * There must be a bid exists
     * remove this bid record
     */
    function withdrawBidForToken(address sender, uint256 tokenId) external returns (address, uint256 bidPrice) {
        Bid memory bid = _tokenBids[tokenId].bids[sender];
        require(bid.bidder == sender, "This address doesn't have bid on this token");

        emit TokenBidWithdrawn(tokenId, bid.bidder, bid.bidPrice, _erc721Name);
        _removeBidOfBidder(tokenId, sender);
        return (bid.bidder, bid.bidPrice);
    }

    

    /**
     * @dev See {INFTKEYMarketPlaceV1-getInvalidListingCount}.
     */
    function getInvalidListingCount() external view override returns (uint256) {
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
    function getInvalidBidCount() external view override returns (uint256) {
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
     * @dev See {INFTKEYMarketPlaceV1-erc721Name}.
     */
    function erc721Name() external view override returns (string memory) {
        return _erc721Name;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-isListingAndBidEnabled}.
     */
    function isListingAndBidEnabled() external view override returns (bool) {
        return _isListingAndBidEnabled;
    }

    /**
     * @dev Enable to disable Bids and Listing
     */
    function changeMarketplaceStatus(bool enabled) external onlyDev {
        _isListingAndBidEnabled = enabled;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-actionTimeOutRangeMin}.
     */
    function actionTimeOutRangeMin() external view override returns (uint256) {
        return _actionTimeOutRangeMin;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-actionTimeOutRangeMax}.
     */
    function actionTimeOutRangeMax() external view override returns (uint256) {
        return _actionTimeOutRangeMax;
    }

    /**
     * @dev Change minimum listing and bid time range
     */
    function changeMinActionTimeLimit(uint256 timeInSec) external onlyDev {
        _actionTimeOutRangeMin = timeInSec;
    }

    /**
     * @dev Change maximum listing and bid time range
     */
    function changeMaxActionTimeLimit(uint256 timeInSec) external onlyDev {
        _actionTimeOutRangeMax = timeInSec;
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-serviceFee}.
     * @param nftAddress nft token address for getting service fee
     * @return feeTokenSeller
     * @return feeTokenCreater
     * @return feeNFTDev
     * @return feeFraction
     * @return feeBase
     */
    // function serviceFee() external view override returns (uint256, uint256) {
    //     return (_feeFraction, _feeTokenBase);
    // }
    function serviceFee(address nftAddress) external view override returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        require(_baseFeeTokenBase == 1000, "This token is not registed");
        return (
            _baseFeeTokenSeller, 
            _baseFeeTokenProducer, 
            _baseFeeTokenCreater, 
            _baseFeeTokenDev, 
            _baseFeeFraction, 
            _baseFeeTokenBase
        );
    }

    // /**
    //  * @dev Set nft tokens fees
    //  * @param _nftAddress Token maket fee address
    //  * @param _feeSeller Token seller fee address
    //  * @param _feeCreater Token creater fee address
    //  * @param _feeDev Token dev fee address
    //  */
    function setNFTFees(
        address _nftAddress,
        uint256 _feeCreater,
        uint256 _feeProducer
        )
        external
        onlyDev
    {
        require(
            _feeCreater == 0 || nftCreaterAddress != address(0), "This token don't set creater address"
        );
        require(
            _feeProducer == 0 || nftProducerAddress != address(0), "This token don't set producer address"
        );

        _baseFeeTokenCreater = _feeCreater;
        _baseFeeTokenProducer = _feeProducer;
        _baseFeeTokenSeller = _baseFeeTokenBase - _baseFeeTokenCreater - _baseFeeTokenDev - _baseFeeTokenProducer;
        _baseFeeFraction = _baseFeeTokenCreater + _baseFeeTokenDev + _baseFeeTokenProducer;
    }

    /**
     * @dev Set partner address and profit share
     * @param _nftAddress Token maket fee address
     * @param _maketPlaceFeeAddress Token maket fee address
     * @param _maketPlaceFeePercentage Token maket place fee for 1000
     */
    function setMaketPlaceAddressAndDevFee(
        address _nftAddress,
        address _maketPlaceFeeAddress, 
        uint256 _maketPlaceFeePercentage)
        external
        onlyDev
    {
        require(
            _maketPlaceFeePercentage > 0 && _maketPlaceFeePercentage <= 1000,
            "Allowed percentage range is 1 to 1000"
        );
        maketPlaceFeeAddress = _maketPlaceFeeAddress;
        require(
            1000 == _baseFeeTokenBase, "This token is not registed"
        );

        _baseFeeTokenDev = _maketPlaceFeePercentage;
        _baseFeeTokenSeller = _baseFeeTokenBase - _baseFeeTokenDev - _baseFeeTokenCreater - _baseFeeTokenProducer; 
        _baseFeeFraction = _baseFeeTokenDev + _baseFeeTokenCreater - _baseFeeTokenProducer;
    }

    /**
     * @dev Set partner address and profit share
     * @param _nftAddress Token maket fee address
     * @param _tokenCreaterAddress Token maket fee address
     */
    function setTokenCreaterAddress(
        address _nftAddress,
        address _tokenCreaterAddress)
        external
        onlyDev
    {
        require(_tokenCreaterAddress != address(0), "Can't set to address 0x0");
        require(
            1000 == _baseFeeTokenBase, "This token is not registed"
        );
        nftCreaterAddress = _tokenCreaterAddress;
    }

    /**
     * @dev Set partner address and profit share
     * @param _nftAddress Token maket fee address
     * @param _tokenProducerAddress Token maket fee address
     */
    function setTokenProducerAddress(
        address _nftAddress,
        address _tokenProducerAddress)
        external
        onlyDev
    {
        require(_tokenProducerAddress != address(0), "Can't set to address 0x0");
        require(
            1000 == _baseFeeTokenBase, "This token is not registed"
        );
        nftProducerAddress = _tokenProducerAddress;
    }

    /**
     * @dev Change partner address
     * @param _nftAddress Token maket fee address
     * @param _tokenCreaterAddress Partner address
     * Only partner can change their share address
     */
    function changeTokenCreaterAddress(
        address _nftAddress,
        address _tokenCreaterAddress) external {
        nftCreaterAddress = _tokenCreaterAddress;
    }

    function changeDev(address _newDev) public onlyDev {
        dev  = _newDev;
    }

}