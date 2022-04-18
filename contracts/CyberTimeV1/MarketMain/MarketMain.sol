// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../marketPlace/CyberBoxMarket.sol";
import "../marketPlace/Interface.sol";
import "./MarketInterface.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract MarketMain is MarketInterface, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private atContract;
    address public implementation;

    address public ownerAddress; // developer address
    address public devAddress; // developer address

    struct Token {
        string tokenName;
        string tokenSymbol;
        address tokenAddress;
    }

    struct NFTToken {
        Token nftToken;
        Token paymentToken;
        address marketPlaceAddress;
    }

    mapping(address => NFTToken) private _nftManager;
    address private _selectedNftAddress;
    IERC721 private _erc721;
    address private _selectedPayTokenAddress;
    IERC20 private _paymentToken;
    CyberBoxMarket private _selectedMarketPlaceToken;

    constructor(
        address _ownerAddress,
        address _devAddress,
        address _maketPlaceAddress
    ) public {
        ownerAddress = _ownerAddress;
        devAddress = _devAddress;
        implementation = _maketPlaceAddress;
    }

    /**
     * @dev get support nft list
     * The seller must be the dev
     * nftName: display name of nft
     * nftSymbol: nft token symbol
     * nftAddress: nft token address
     */
    function getSupportNFTToken(address _nftAddress) external view returns (Token memory) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        return nftToken.nftToken;
    }
    function getSupportPaymentToken(address _nftAddress) external view returns (Token memory) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        return nftToken.paymentToken;
    }
    function getSupportMarketPlaceToken(address _nftAddress) external view returns (address) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        console.log("getSupportMarketPlaceToken", nftToken.marketPlaceAddress);
        return nftToken.marketPlaceAddress;
    }
    /**
     * @dev add new nft to contract
     * The seller must be the dev
     * nftName: display name of nft
     * nftSymbol: nft token symbol
     * nftAddress: nft token address
     */
    function addNFTToken(
        string memory _nftName, 
        string memory _nftSymbol, 
        address _nftAddress,
        string memory _erc20Name, 
        string memory _erc20Symbol, 
        address _erc20Address
    ) external onlyDev {
        
        if(_nftManager[_nftAddress].marketPlaceAddress == address(0)){

            _nftManager[_nftAddress].nftToken = Token(_nftName, _nftSymbol, _nftAddress);
            _nftManager[_nftAddress].paymentToken = Token(_erc20Name, _erc20Symbol, _erc20Address);

            createNewMarketPlaceToken(_nftName, _nftAddress, _erc20Address, devAddress);
            NFTToken memory nftToken =  _nftManager[_nftAddress];
            emit CyberMarketTokenAdded(
                _nftName,
                _nftSymbol,
                _nftAddress,
                _erc20Name,
                _erc20Symbol,
                _erc20Address,
                nftToken.marketPlaceAddress
            );

        }else{
            selectNFT(_nftAddress);
        }
    }
    /**
     * @dev set marketPlace address and fee of nft contract
     * nftAddress: nft token address
    */
    function changeERC20Token(
        address _nftAddress,
        string memory _erc20Name, 
        string memory _erc20Symbol, 
        address _erc20Address)
        external
        onlyDev
    {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _paymentToken = IERC20(_erc20Address);
        _selectedPayTokenAddress = _erc20Address;
        _nftManager[_nftAddress].paymentToken = Token(_erc20Name, _erc20Symbol, _erc20Address);
        emit CyberMarketTokenChanged(
                _nftAddress,
                _erc20Name,
                _erc20Symbol,
                _erc20Address,
                nftToken.marketPlaceAddress
            );
    }
    /**
     * @dev set marketPlace address and fee of nft contract
     * nftAddress: nft token address
    */
    function setMaketPlaceAddressAndDevFee(
        address _nftAddress,
        address _maketPlaceFeeAddress, 
        uint256 _maketPlaceFeePercentage)
        external
        onlyDev
    {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.setMaketPlaceAddressAndDevFee(
            _nftAddress,
            _maketPlaceFeeAddress,
            _maketPlaceFeePercentage
        );
        emit CyberMarketDevFeeChanged(
            _nftAddress,
            _maketPlaceFeeAddress,
            _maketPlaceFeePercentage
        );
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
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.setTokenCreaterAddress(
            _nftAddress,
            _tokenCreaterAddress
        );
        emit CyberMarketTokenCreaterChanged(
            _nftAddress,
            _tokenCreaterAddress
        );
    }
    function setTokenProducerAddress(
        address _nftAddress,
        address _tokenProducerAddress)
        external
        onlyDev
    {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.setTokenProducerAddress(
            _nftAddress,
            _tokenProducerAddress
        );
        emit CyberMarketTokenProducerChanged(
            _nftAddress,
            _tokenProducerAddress
        );
    }
    /**
     * @dev return token fee of nft contract
     * nftAddress: nft token address
    */
    function serviceFee() external view 
    returns (uint256, uint256, uint256, uint256, uint256, uint256) 
    {
        return _selectedMarketPlaceToken.serviceFee(_selectedNftAddress);
    }
    /**
     * @dev set token fee to nft contract
     * nftAddress: nft token address
    */
    function setNFTFees(
        address _nftAddress,
        uint256 _feeCreater,
        uint256 _feeProducer
    )
    external
    onlyDev
    {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.setNFTFees(
            _nftAddress,
            _feeCreater,
            _feeProducer
        );
        emit CyberMarketFeeChanged(
            _nftAddress,
            _feeCreater,
            _feeProducer
        );
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-enterBidForToken}.
     * People can only enter bid if bid is allowed
     * The timestamp set needs to be in the allowed range
     * bid price > 0
     * must not be token owner
     * must allow this contract to spend enough pay
     ment token
     */
    function enterBidForToken(
        address _nftAddress,
        uint256 tokenId,
        uint256 bidPrice,
        uint256 expireTimestamp
    ) external payable{
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        if(isEtherToken() == true){
            // payable(msg.sender).transfer(msg.value);
            // Address.sendValue(payable(address(this)), msg.value);
            _selectedMarketPlaceToken.enterBidForToken(msg.sender, tokenId, msg.value, expireTimestamp);
            emit CyberMarketTokenBidEntered(
            nftToken.nftToken.tokenAddress,
            tokenId,
            msg.sender,
            msg.value
            );
        }else{
            transferERC20(msg.sender, address(this), bidPrice);
            _selectedMarketPlaceToken.enterBidForToken(msg.sender, tokenId, bidPrice, expireTimestamp);
            emit CyberMarketTokenBidEntered(
            nftToken.nftToken.tokenAddress,
            tokenId,
            msg.sender,
            bidPrice
            );
        }
    }


    /**
     * @dev See {INFTKEYMarketPlaceV1-acceptBidForToken}.
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches the bidder address
     */
    function acceptBidForToken(
        address _nftAddress,
        uint256 tokenId, 
        address bidder
    ) external{
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
            address devAddress,
            address createrAddress,
            address producerAddress,
            uint256 bidAmount
            ) = _selectedMarketPlaceToken.acceptBidForTokenPrepare(msg.sender, tokenId, bidder);
        
        uint256 sellerFee = _selectedMarketPlaceToken.calculateSellerFee(bidAmount);
        uint256 devFee = _selectedMarketPlaceToken.calculateDevFee(bidAmount);
        uint256 createrFee = _selectedMarketPlaceToken.calculateCreaterFee(bidAmount);
        uint256 producerFee = _selectedMarketPlaceToken.calculateCreaterFee(bidAmount);
        
        if(isEtherToken() == true){
            payable(msg.sender).transfer(sellerFee);
            payable(devAddress).transfer(devFee);
            if(createrAddress != address(0) && createrFee > 0){
                payable(createrAddress).transfer(createrFee);
            }
            if(producerAddress != address(0) && producerFee > 0){
                payable(producerAddress).transfer(producerFee);
            }
        }else{
            transferERC20(address(this), msg.sender, sellerFee);
            transferERC20(address(this), devAddress, devFee);
            transferERC20(address(this), createrAddress, createrFee);
            transferERC20(address(this), producerAddress, producerFee);
        }
        
        _selectedMarketPlaceToken.acceptBidForTokenComplete(msg.sender, tokenId, bidder);

        emit CyberMarketTokenBidAccepted(
            nftToken.nftToken.tokenAddress,
            tokenId,
            msg.sender,
            bidder,
            bidAmount,
            sellerFee,
            devFee + createrFee + producerFee
        );
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-buyToken}.
     * Must have a valid listing
     * msg.sender must not the owner of token
     * msg.value must be at least sell price plus fees
     */
    function buyToken(
        address _nftAddress,
        uint256 tokenId,
        uint256 value
    ) external payable{
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
            address sellerAddress, 
            address devAddress,
            address createrAddress,
            address producerAddress
            ) = _selectedMarketPlaceToken.buyTokenPrepare(msg.sender, tokenId, value);

            uint256 payment_value = value;
            if(isEtherToken() == true){
                payment_value = msg.value;
            }
            
            uint256 sellerFee = _selectedMarketPlaceToken.calculateSellerFee(payment_value);
            uint256 devFee = _selectedMarketPlaceToken.calculateDevFee(payment_value);
            uint256 createrFee = _selectedMarketPlaceToken.calculateCreaterFee(payment_value);
            uint256 producerFee = _selectedMarketPlaceToken.calculateCreaterFee(payment_value);
            if(isEtherToken() == true){
                Address.sendValue(payable(sellerAddress), sellerFee);
                Address.sendValue(payable(devAddress), devFee);
                if(createrAddress != address(0) && createrFee > 0){
                    Address.sendValue(payable(createrAddress), createrFee);
                }
                if(producerAddress != address(0) && producerFee > 0){
                    Address.sendValue(payable(producerAddress), producerFee);
                }
            }else{
                transferERC20(msg.sender, sellerAddress, sellerFee);
                transferERC20(msg.sender, devAddress, devFee);
                transferERC20(msg.sender, createrAddress, createrFee);
                transferERC20(msg.sender, producerAddress, producerFee);
            }
            
            _selectedMarketPlaceToken.buyTokenComplete(msg.sender, tokenId);
            emit CyberMarketTokenBought(
                 _nftAddress,
                 tokenId,
                 sellerAddress,
                 msg.sender,
                 payment_value,
                 sellerFee,
                 devFee + createrFee + producerFee
            );
    }

    function transferERC20(address sender, address receiver, uint256 value) private{
        if (receiver != address(0) && value > 0) {
            if(sender == address(this)){
                _paymentToken.transfer(receiver, value);
                // payable(receiver).transfer(value);
            }else{
                _paymentToken.transferFrom(sender, receiver, value);
            }
        }
    }
    function isEtherToken() private returns (bool){
        if(_selectedPayTokenAddress == address(0x471EcE3750Da237f93B8E339c536989b8978a438) ||
        _selectedPayTokenAddress == address(0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9)){
            return true;
        }
        return false;
    }

/**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     * @param expireTimestamp when would this listing expire
     */
    function listToken(
        address _nftAddress,
        uint256 tokenId,
        uint256 value,
        uint256 expireTimestamp
    ) external  {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
        address fromAddress, 
        uint256 minValue
        ) = _selectedMarketPlaceToken.listToken(msg.sender, tokenId, value, expireTimestamp);
        emit CyberMarketTokenListed(
            nftToken.nftToken.tokenAddress,
            tokenId,
            fromAddress,
            minValue
        );
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-delistToken}.
     * msg.sender must be the seller of the listing record
     */
    function delistToken(
        address _nftAddress,
        uint256 tokenId
    ) external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.delistToken(msg.sender, tokenId);
        emit CyberMarketTokenDelisted(
            nftToken.nftToken.tokenAddress,
            tokenId
        );
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidListings}.
     */
    function cleanAllInvalidListings(address _nftAddress) external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (uint256[] memory idList) = _selectedMarketPlaceToken.cleanAllInvalidListings();
        for (uint256 i = 0; i < idList.length; i++) {
            uint256 contract_id = idList[i];
            emit CyberMarketCleanList(
                nftToken.nftToken.tokenAddress,
                contract_id
            );
        }
        
        _selectedMarketPlaceToken.deleteTempTokenIdStorage();
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidBids}.
     */
    function cleanAllInvalidBids(address _nftAddress) external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (uint256[] memory idList) = _selectedMarketPlaceToken.cleanAllInvalidBids();
        for (uint256 i = 0; i < idList.length; i++) {
            uint256 contract_id = idList[i];
            emit CyberMarketCleanBid(
                nftToken.nftToken.tokenAddress,
                contract_id
            );
        }
        _selectedMarketPlaceToken.deleteTempTokenIdStorage();
    }

    /**
     * @dev Transfer token to Other
     * Must be owner of this token
     * Must have approved this contract to transfer token
     * Must have a valid existing bid that matches the bidder address
    */
    function transfer(
        address _nftAddress,
        address to,
        uint256 tokenId
    )external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.transfer(msg.sender, to, tokenId);
        emit CyberMarketTokenTransfered(
            _nftAddress,
            tokenId,
            msg.sender,
            to,
            0
        );
    }
    /**
     * @dev change price for already listed token.
     * Must have a valid listing
     * msg.sender must not the owner of token
     */
    function changePrice(address _nftAddress, uint256 tokenId, uint256 newPrice) external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        _selectedMarketPlaceToken.changePrice(msg.sender, tokenId, newPrice);
        emit CyberMarketTokenPriceChanged(
            _nftAddress,
            tokenId,
            newPrice
        );
    }
    

    /**
     * @dev See {INFTKEYMarketPlaceV1-withdrawBidForToken}.
     * There must be a bid exists
     * remove this bid record
     */
    function withdrawBidForToken(
        address _nftAddress,
        uint256 tokenId
    ) external {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (address bidder, uint256 bidPrice) = _selectedMarketPlaceToken.withdrawBidForToken(msg.sender, tokenId);
        if(isEtherToken() == true){
            payable(bidder).transfer(bidPrice);
        }else{
            transferERC20(address(this), bidder, bidPrice);
        }
        emit CyberMarketTokenBidWithdrawn(
            _nftAddress,
            tokenId,
            bidder
        );
    }


    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenListing}.
     */
    function getTokenListing(
        uint256 tokenId
    ) public view 
    returns (Interface.Listing memory) {
        return _selectedMarketPlaceToken.getTokenListing(tokenId);
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getAllTokenListings}.
     */
    function getAllTokenListings() external view returns (Interface.Listing[] memory) {
        return _selectedMarketPlaceToken.getAllTokenListings();
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenBids}.
     */
    function getTokenBids(uint256 tokenId) external view returns (Interface.Bid[] memory) {
        return _selectedMarketPlaceToken.getTokenBids(tokenId);
    }

    modifier onlyDev() {
        require(msg.sender == devAddress, "auction: wrong developer");
        _;
    }

    function changeDev(address _newDev) public onlyDev {
        devAddress  = _newDev;
    }

    /**
     * @dev create new CyberBoxMarketPlace contract for nft
     * The seller must be the dev
     * _nftName: display name of nft
     * _nftAddress: nft token address
     */
    function createNewMarketPlaceToken(
        string memory _nftName,
        address _nftAddress,
        address _erc20Address,
        address _owner
        ) private {
        
        uint256 newId = atContract.current();
        console.log("newId", newId);
        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementation,
            toBytes(newId)
        );
        _nftManager[_nftAddress].marketPlaceAddress = newContract;
        CyberBoxMarket(newContract).initialize(
            _nftName,
            _nftAddress,
            _erc20Address,
            _owner
        );
        atContract.increment();
    }
    function setNewMarketPlaceAddress(address _newAddress) public onlyDev {
        implementation  = _newAddress;
    }
    /**
     * @dev set active nft to nft address
     * The seller must be the dev
     * _nftAddress: nft token address
    */
    function selectNFTToken(
        address _nftAddress
    ) private {
        if(_nftAddress != _selectedNftAddress){
            _erc721 = IERC721(_nftAddress);
            _selectedNftAddress = _nftAddress;
        }
    }
    /**
     * @dev set active erc20 to erc20 address
     * The seller must be the dev
     * _erc20Address: payment token address
    */
    function selectPaymentToken(
        address _erc20Address
    ) private {
        if(_erc20Address != _selectedPayTokenAddress){
            _paymentToken = IERC20(_erc20Address);
            _selectedPayTokenAddress = _erc20Address;
        }
    }
    /**
     * @dev set active erc20 to erc20 address
     * The seller must be the dev
    */
    function selectNFT(
        address _nftAddress
    ) public {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        Token memory nft = nftToken.nftToken;
        selectNFTToken(nft.tokenAddress);
        Token memory erc20 = nftToken.paymentToken;
        selectPaymentToken(erc20.tokenAddress);
        address marketToken = nftToken.marketPlaceAddress;
        _selectedMarketPlaceToken = CyberBoxMarket(marketToken);
    }

    function toBytes(uint256 x)
        public
        view 
        returns (bytes32 b) {
		return bytes32(keccak256(abi.encodePacked(x)));
	}
}