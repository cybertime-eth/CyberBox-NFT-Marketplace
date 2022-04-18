// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

import "./CyberBoxMarketInterface.sol";
import "./CyberBoxMarketNFTAPI.sol";
import "./CyberBoxMarketPaymentAPI.sol";

contract CyberBoxMarketManager is Ownable, CyberBoxMarketInterface, CyberBoxMarketNFTAPI, CyberBoxMarketPaymentAPI {
    constructor() public {}
    
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

        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().setMaketPlaceAddressAndDevFee(
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().setTokenCreaterAddress(
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().setTokenProducerAddress(
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
    function getServiceFee(address _nftAddress) external 
    returns (uint256, uint256, uint256, uint256, uint256, uint256) 
    {
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        return getMarketPlaceToken().serviceFee(_nftAddress);
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
        NFTToken memory nftToken =  getNFTToken(_nftAddress);
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        selectNFT(_nftAddress);
        getMarketPlaceToken().setNFTFees(
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
}