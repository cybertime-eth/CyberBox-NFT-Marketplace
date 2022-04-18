// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

import "./CyberBoxMarketManager.sol";

contract CyberBoxMarketplace is CyberBoxMarketManager {
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
        uint256 bidPrice
    ) external payable{
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        uint256 price = msg.value;
        if(isEtherToken(getSelectedERC20Address()) == false){
            sendERC20(getSelectedERC20Token(), msg.sender, address(this), bidPrice);
            price = bidPrice;
        }
        getMarketPlaceToken().enterBidForToken(msg.sender, tokenId, msg.value);
        emit CyberMarketTokenBidEntered(
            nftToken.nftToken.tokenAddress,
            tokenId,
            msg.sender,
            price
        );
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
            address devAddress,
            address createrAddress,
            address producerAddress,
            uint256 bidAmount
            ) = getMarketPlaceToken().acceptBidForTokenPrepare(msg.sender, tokenId, bidder);
        
        uint256 sellerFee = getMarketPlaceToken().calculateSellerFee(bidAmount);
        uint256 devFee = getMarketPlaceToken().calculateDevFee(bidAmount);
        uint256 createrFee = getMarketPlaceToken().calculateCreaterFee(bidAmount);
        uint256 producerFee = getMarketPlaceToken().calculateProducerFee(bidAmount);
        sendERC20(getSelectedERC20Token(), address(this), msg.sender, sellerFee);
        sendERC20(getSelectedERC20Token(), address(this), devAddress, devFee);
        if(createrAddress != address(0) && createrFee > 0){
            sendERC20(getSelectedERC20Token(), address(this), createrAddress, createrFee);
        }
        if(producerAddress != address(0) && producerFee > 0){
            sendERC20(getSelectedERC20Token(), address(this), producerAddress, producerFee);
        }
        getMarketPlaceToken().acceptBidForTokenComplete(msg.sender, tokenId, bidder);

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
     * @dev See {INFTKEYMarketPlaceV1-withdrawBidForToken}.
     * There must be a bid exists
     * remove this bid record
     */
    function withdrawBidForToken(
        address _nftAddress,
        uint256 tokenId
    ) external {
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (address bidder, uint256 bidPrice) = getMarketPlaceToken().withdrawBidForToken(msg.sender, tokenId);
        sendERC20(getSelectedERC20Token(), address(this), bidder, bidPrice);
        emit CyberMarketTokenBidWithdrawn(
            _nftAddress,
            tokenId,
            bidder
        );
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidBids}.
     */
    function cleanAllInvalidBids() external {
        for(uint256 nftId = 0; nftId < supportNFTs.length; nftId ++){
            address _nftAddress = supportNFTs[nftId];
            NFTToken memory nftToken =  getNFTToken(_nftAddress);
            if(nftToken.marketPlaceAddress != address(0)){
                selectNFT(_nftAddress);
                (uint256[] memory idList) = getMarketPlaceToken().cleanAllInvalidBids();
                for (uint256 i = 0; i < idList.length; i++) {
                    uint256 contract_id = idList[i];
                    emit CyberMarketCleanBid(
                        nftToken.nftToken.tokenAddress,
                        contract_id
                    );
                }
                getMarketPlaceToken().deleteTempTokenIdStorage();
            }
        }
    }
    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     */
    function listToken(
        address _nftAddress,
        uint256 tokenId,
        uint256 value
    ) external  {
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
        address fromAddress, 
        uint256 minValue
        ) = getMarketPlaceToken().listToken(msg.sender, tokenId, value);
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().delistToken(msg.sender, tokenId);
        emit CyberMarketTokenDelisted(
            nftToken.nftToken.tokenAddress,
            tokenId
        );
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidListings}.
     */
    function cleanAllInvalidListings() external {
        for(uint256 nftId = 0; nftId < supportNFTs.length; nftId ++){
            address _nftAddress = supportNFTs[nftId];
            NFTToken memory nftToken =  getNFTToken(_nftAddress);
            if(nftToken.marketPlaceAddress != address(0)){
                selectNFT(_nftAddress);
                (uint256[] memory idList) = getMarketPlaceToken().cleanAllInvalidListings();
                for (uint256 i = 0; i < idList.length; i++) {
                    uint256 contract_id = idList[i];
                    emit CyberMarketCleanList(
                        nftToken.nftToken.tokenAddress,
                        contract_id
                    );
                }
                getMarketPlaceToken().deleteTempTokenIdStorage();
            }
        }

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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        (
            address sellerAddress, 
            address devAddress,
            address createrAddress,
            address producerAddress
            ) = getMarketPlaceToken().buyTokenPrepare(msg.sender, tokenId, value);

            uint256 payment_value = value;
            if(isEtherToken(getSelectedERC20Address()) == true){
                payment_value = msg.value;
            }
            
            uint256 sellerFee = getMarketPlaceToken().calculateSellerFee(payment_value);
            uint256 devFee = getMarketPlaceToken().calculateDevFee(payment_value);
            uint256 createrFee = getMarketPlaceToken().calculateCreaterFee(payment_value);
            uint256 producerFee = getMarketPlaceToken().calculateProducerFee(payment_value);
            sendERC20(getSelectedERC20Token(), msg.sender, sellerAddress, sellerFee);
            sendERC20(getSelectedERC20Token(), msg.sender, devAddress, devFee);
            if(createrAddress != address(0) && createrFee > 0){
                sendERC20(getSelectedERC20Token(), msg.sender, createrAddress, createrFee);
            }
            if(producerAddress != address(0) && producerFee > 0){
                sendERC20(getSelectedERC20Token(), msg.sender, producerAddress, producerFee);
            }
            getMarketPlaceToken().buyTokenComplete(msg.sender, tokenId);
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().transfer(msg.sender, to, tokenId);
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().changePrice(msg.sender, tokenId, newPrice);
        emit CyberMarketTokenPriceChanged(
            _nftAddress,
            tokenId,
            newPrice
        );
    }
    
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenListing}.
     */
    function getTokenListing(
        uint256 tokenId
    ) public view 
    returns (InterfaceV2.Listing memory) {
        return getMarketPlaceToken().getTokenListing(tokenId);
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getAllTokenListings}.
     */
    function getAllTokenListings() external view returns (InterfaceV2.Listing[] memory) {
        return getMarketPlaceToken().getAllTokenListings();
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-getTokenBids}.
     */
    function getTokenBids(uint256 tokenId) external view returns (InterfaceV2.Bid[] memory) {
        return getMarketPlaceToken().getTokenBids(tokenId);
    }

    function withdrawCelo(address receiver) external onlyDev {
        require(receiver != address(0), "transfer address must not 0x0");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "contract must have celo");
        payable(receiver).transfer(contractBalance);
    }
    function withdrawERC20(address address20, address receiver) external onlyDev {
        require(receiver != address(0), "transfer address must not 0x0");
        IERC20 _paymentToken = IERC20(address20);
        uint256 contractBalance = _paymentToken.balanceOf(address(this));
        require(contractBalance > 0, "contract must have celo");
        _paymentToken.transfer(receiver, contractBalance);
    }
}