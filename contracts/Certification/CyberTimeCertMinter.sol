// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

import "./DateTimeManager.sol";
import "./CyberTimeCertNFT.sol";
import "./CyberTimeCertInterface.sol";
import "./CyberTimeCertResource.sol";
import "./Uniswap/uniswpv2.sol";

import "./MarketPlace/CertificationMarketPlace.sol";

contract CyberTimeCertMinter is DateTimeManager, CyberTimeCertInterface, CyberTimeCertResource, CertificationMarketPlace {
    using Address for address;

    struct NFTMAP  {
        uint256 tokenType;
        uint256 year;
        uint256 month;
    }

    address public dev;
    address public owner;
    address public carbonAdd;
    uint256 public carvonFee;

    address public linkedNFTAddress;

    address private constant UNISWAP_V2_ROUTER = 0xE3D8bd6Aed4F159bc8000a9cD47CffDb95F96121;
    address private constant WETH = 0x471EcE3750Da237f93B8E339c536989b8978a438;
    address public CMCO2 = 0x32A9FE697a32135BFd313a6Ac28792DaE4D9979d;
    
    //////// owner address => year_month_key => token id
    mapping (address => mapping(uint256 => uint256)) private _ownedMonthData;
    mapping (address => mapping(uint256 => uint256)) private _ownedYearData;
    mapping (address => mapping(uint256 => uint256)) private _ownedBonusData;

    mapping (uint256 => NFTMAP) private _nftDateMap;
    

    uint256 private TOKEN_TYPE_MONTH = 0;
    uint256 private TOKEN_TYPE_YEAR = 1;
    uint256 private TOKEN_TYPE_BONUS = 2;

    constructor(
        address _nft,
        address _dev,
        address _owner,
        address _carvon
    ) public {
        linkedNFTAddress = _nft;
        initializeWithERC721(_nft, _owner);
        dev = _dev;
        owner = _owner;
        carbonAdd = _carvon;
        carvonFee = 25;
    }

    function uniwapMCO(address _to, uint256 _amountIn) public returns (uint256[] memory amounts){
        IERC20(WETH).approve(UNISWAP_V2_ROUTER, _amountIn);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = CMCO2;
        return IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, 0, path, _to, block.timestamp);
    }

    function mintMonthNFT() external payable {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        uint256 current_nft_id = getCurrentMonthNFTID(msg.sender);
        require(current_nft_id < 1, "This user already mint nft for this month.");
        require(msg.value > 0, "This user must pay for mint nft.");

        uint256 totalValue = msg.value;
        uint256 c02Fee = (totalValue * carvonFee) /1000;
        uint256 sellerFee = totalValue - c02Fee;

        payable(owner).transfer(sellerFee);
        uint256[] memory amounts = uniwapMCO(owner, c02Fee);
        uint256 co2Value = amounts[amounts.length - 1];
        
        string memory token_uri = getMonthTokenURI(year, month);
        uint256 nft_id = CyberTimeCertNFT(linkedNFTAddress).mintNFT(msg.sender, token_uri);
        _ownedMonthData[msg.sender][year*100 + month] = nft_id;
        _nftDateMap[nft_id] = NFTMAP(TOKEN_TYPE_MONTH, year, month);
        emit CertificationNFTMinted(msg.sender, TOKEN_TYPE_MONTH, nft_id, year, month, totalValue, co2Value);
    }

    function mintMonthNFTFor(address receipt, uint256 year, uint256 month) private {
        uint256 current_nft_id = getMonthNFTID(receipt, year, month);
        if(current_nft_id < 1) {
            string memory token_uri = getMonthTokenURI(year, month);
            uint256 nft_id = CyberTimeCertNFT(linkedNFTAddress).mintNFT(msg.sender, token_uri);
            _ownedMonthData[msg.sender][year*100 + month] = nft_id;
            _nftDateMap[nft_id] = NFTMAP(TOKEN_TYPE_MONTH, year, month);
            emit CertificationNFTMinted(msg.sender, TOKEN_TYPE_MONTH, nft_id, year, month, 0, 0);
        }
    }

    function mintYearNFT()  external payable  {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        uint256 current_nft_id = getCurrentYearNFTID(msg.sender);
        require(current_nft_id < 1, "This user already mint nft for this month.");
        require(msg.value > 0, "This user must pay for mint nft.");
        
        uint256 totalValue = msg.value;
        uint256 c02Fee = (totalValue * carvonFee) /1000;
        uint256 sellerFee = totalValue - c02Fee;

        payable(owner).transfer(sellerFee);
        uint256[] memory amounts = uniwapMCO(owner, c02Fee);
        
        uint256 co2Value = amounts[amounts.length - 1];

        string memory token_uri = getYearTokenURI(year);
        uint256 nft_id = CyberTimeCertNFT(linkedNFTAddress).mintNFT(msg.sender, token_uri);
        _ownedYearData[msg.sender][year] = nft_id;
        _nftDateMap[nft_id] = NFTMAP(TOKEN_TYPE_YEAR, year, 0);
        emit CertificationNFTMinted(msg.sender, TOKEN_TYPE_YEAR, nft_id, year, 0, totalValue, co2Value);
    }

    function mintBonusNFT() external payable {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        uint256 current_nft_id = getCurrentBonusNFTID(msg.sender);
        require(current_nft_id < 1, "This user already mint nft for this month.");
        require(msg.value > 0, "This user must pay for mint nft.");

        uint256 totalValue = msg.value;
        uint256 c02Fee = (totalValue * carvonFee) /1000;
        uint256 sellerFee = totalValue - c02Fee;

        payable(owner).transfer(sellerFee);
        uint256[] memory amounts = uniwapMCO(owner, c02Fee);
        uint256 co2Value = amounts[amounts.length - 1];

        string memory token_uri = getBonusTokenURI(year);
        uint256 nft_id = CyberTimeCertNFT(linkedNFTAddress).mintNFT(msg.sender, token_uri);
        _ownedBonusData[msg.sender][year] = nft_id;
        _nftDateMap[nft_id] = NFTMAP(TOKEN_TYPE_BONUS, year, 0);
        emit CertificationNFTMinted(msg.sender, TOKEN_TYPE_BONUS, nft_id, year, 0, totalValue, co2Value);
    }

    function exchangeBonusNFTToMonth(uint256 year) public {
        uint256 current_nft_id = getBonusNFTID(msg.sender, year);
        require(current_nft_id > 0, "This user don't have bonus NFT.");
        CyberTimeCertNFT(linkedNFTAddress).burn(msg.sender, current_nft_id);
        _ownedBonusData[msg.sender][year] = 0;
        emit CertificationNFTBurned(msg.sender, TOKEN_TYPE_BONUS, current_nft_id, year, 0);
        for(uint256 month = 1; month<=12; month++){
            mintMonthNFTFor(msg.sender, year, month);
        }
    }

    function exchangeMonthNFTToBonus(uint256 year) public {
        uint256 current_bonus_id = getCurrentBonusNFTID(msg.sender);
        require(current_bonus_id < 1, "This user already mint nft for this month.");
        for(uint256 month = 1; month<=12; month++){
            uint256 current_nft_id = getMonthNFTID(msg.sender, year, month);
            require(current_nft_id > 0, "This user don't have all month NFT.");
            CyberTimeCertNFT(linkedNFTAddress).burn(msg.sender, current_nft_id);
            _ownedMonthData[msg.sender][year*100 + month] = 0;
            emit CertificationNFTBurned(msg.sender, TOKEN_TYPE_MONTH, current_nft_id, year, 0);
        }
        string memory token_uri = getBonusTokenURI(year);
        uint256 nft_id = CyberTimeCertNFT(linkedNFTAddress).mintNFT(msg.sender, token_uri);
        _ownedBonusData[msg.sender][year] = nft_id;
        emit CertificationNFTMinted(msg.sender, TOKEN_TYPE_BONUS, nft_id, year, 0, 0, 0);
    }

    function transferNFTOwnedData(address from, address to, uint256 tokenId) private {
        NFTMAP memory mapData = _nftDateMap[tokenId];
        uint256 tokenType = mapData.tokenType;
        uint256 year = mapData.year;
        uint256 month = mapData.month;
        if (tokenType == TOKEN_TYPE_MONTH){
            _ownedMonthData[from][year*100 + month] = 0;
            _ownedMonthData[to][year*100 + month] = tokenId;
        }
        if (tokenType == TOKEN_TYPE_YEAR) {
            _ownedYearData[from][year] = 0;
            _ownedYearData[to][year] = tokenId;
        }
        if (tokenType == TOKEN_TYPE_BONUS) {
            _ownedBonusData[from][year] = 0;
            _ownedBonusData[to][year] = tokenId;
        }
    }


    function getMonthNFTID(address owner, uint256 year, uint256 month) public returns (uint256){
        console.log("getMonthNFTID", year, month, _ownedMonthData[owner][year * 100 + month]);
        return _ownedMonthData[owner][year * 100 + month];
    }

    function getYearNFTID(address owner, uint256 year) public returns (uint256) {
        console.log("getYearNFTID", year, _ownedBonusData[owner][year]);
        return _ownedYearData[owner][year];
    }

    function getBonusNFTID(address owner, uint256 year) public returns (uint256) {
        console.log("getBonusNFTID", year, _ownedBonusData[owner][year]);
        return _ownedBonusData[owner][year];
    }

    
    function getCurrentMonthNFTID(address owner) public returns (uint256) {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        return _ownedMonthData[owner][year * 100 + month];
    }
    function getCurrentYearNFTID(address owner) public returns (uint256) {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        return _ownedYearData[owner][year];
    }
    function getCurrentBonusNFTID(address owner) public returns (uint256) {
        (uint256 year, uint256 month) = getDateTimeSymbol();
        return _ownedBonusData[owner][year];
    }
    
    
    function changeDev(address _newDev) public onlyDev {dev  = _newDev;}
    function changeOwner(address _newOnwer) public onlyDev {owner  = _newOnwer;}

    function changeCarvonTokenAddress(address _carvonToken) public onlyDev {CMCO2 = _carvonToken;}
    function changeCarvonFeeAddress(address _carvon) public onlyDev {carbonAdd = _carvon;}
    function changeCarvonFee(uint256 _carvonFee) public onlyDev {carvonFee = _carvonFee;}

    modifier onlyDev() { require(msg.sender == dev, "CyberTimeCertNFT: wrong developer");_;}

    /**
     * @dev List token for sale
     * @param tokenId erc721 token Id
     * @param value min price to sell the token
     */
    function listToken(
        uint256 tokenId,
        uint256 value
    ) external  {
        (
        address fromAddress, 
        uint256 minValue
        ) = listToken(msg.sender, tokenId, value);
        emit CertificationTokenListed(
            linkedNFTAddress,
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
        uint256 tokenId
    ) external {
        delistToken(msg.sender, tokenId);
        emit CertificationTokenDelisted(
            linkedNFTAddress,
            tokenId
        );
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-cleanAllInvalidListings}.
     */
    function cleanAllInvalidListings() external {
        (uint256[] memory idList) = certCleanAllInvalidListings();
        for (uint256 i = 0; i < idList.length; i++) {
            uint256 contract_id = idList[i];
            emit CertificationCleanList(
                linkedNFTAddress,
                contract_id
            );
        }
        deleteTempTokenIdStorage();
    }

    function buyToken(
        uint256 tokenId,
        uint256 value
    ) external payable{
        (
            address sellerAddress, 
            address devAddress,
            address createrAddress,
            address producerAddress
        ) = buyTokenPrepare(msg.sender, tokenId, value);
        uint256 payment_value = msg.value;
        address nftAddress = linkedNFTAddress;
        uint256 sellerFee = calculateSellerFee(payment_value);
        uint256 devFee = calculateDevFee(payment_value);
        uint256 createrFee = calculateCreaterFee(payment_value);
        uint256 producerFee = calculateProducerFee(payment_value);
        transferCelo(msg.sender, sellerAddress, sellerFee);
        emit CertificationPayment(msg.sender, sellerAddress, tokenId, nftAddress, 0, sellerFee);
        transferCelo(msg.sender, devAddress, devFee);
        emit CertificationPayment(msg.sender, devAddress, tokenId, nftAddress, 1, devFee);
        if(createrAddress != address(0) && createrFee > 0){
            transferCelo(msg.sender, createrAddress, createrFee);
            emit CertificationPayment(msg.sender, createrAddress, tokenId, nftAddress, 2, createrFee);
        }
        if(producerAddress != address(0) && producerFee > 0){
            transferCelo(msg.sender, producerAddress, producerFee);
            emit CertificationPayment(msg.sender, producerAddress, tokenId, nftAddress, 3, producerFee);
        }
        buyTokenComplete(msg.sender, tokenId);
        transferNFTOwnedData(sellerAddress, msg.sender, tokenId);
        emit CertificationTokenBought(
            nftAddress,
            tokenId,
            sellerAddress,
            msg.sender,
            payment_value,
            sellerFee,
            devFee + createrFee + producerFee
        );
    }

    function transfer(
        address to,
        uint256 tokenId
    )external {
        transfer(msg.sender, to, tokenId);
        transferNFTOwnedData(msg.sender, to, tokenId);
        emit CertificationTokenTransfered(
            linkedNFTAddress,
            tokenId,
            msg.sender,
            to,
            0
        );
    }

    function changePrice(address _nftAddress, uint256 tokenId, uint256 newPrice) external {
        certChangePrice(msg.sender, tokenId, newPrice);
        emit CertificationTokenPriceChanged(
            _nftAddress,
            tokenId,
            newPrice
        );
    }


    function transferCelo(address sender, address receiver, uint256 value)  private{
        require(sender != address(0), "transfer address must not 0x0");
        require(receiver != address(0), "transfer address must not 0x0");
        require(value > 0, "transfer amount must large than 0");
        if(sender == address(this)){
            payable(receiver).transfer(value);
        }else{
            Address.sendValue(payable(receiver), value);
        }
    }
}