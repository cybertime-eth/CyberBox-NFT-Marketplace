// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../MarketPlace/MarketPlaceV2.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./CyberBoxMarketInterface.sol";

contract CyberBoxMarketNFTAPI is CyberBoxMarketInterface  {
    using SafeMath for uint256;
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
        bool is721;
    }

    mapping(address => NFTToken) private _nftManager;
    address private _selectedNftAddress;
    IERC721 private _erc721;
    IERC1155 private _erc1155;
    address private _selectedPayTokenAddress;
    IERC20 private _paymentToken;
    MarketPlaceV2 private _selectedMarketPlaceToken;

    address[] public supportNFTs;

    constructor() public {}

    modifier onlyDev() {
        require(msg.sender == devAddress, "auction: wrong developer");
        _;
    }

    function changeDev(address _newDev) public onlyDev {
        devAddress  = _newDev;
    }

    function getNFTToken(address _nftAddress) public view returns (NFTToken memory){
        return _nftManager[_nftAddress];
    }
    function getMarketPlaceToken() public view returns (MarketPlaceV2){
        return _selectedMarketPlaceToken;
    }
    function getSelectedNFTAddress() public view returns (address){
        return _selectedNftAddress;
    }
    function getSelectedERC20Token() public view returns (IERC20){
        return _paymentToken;
    }
    function getSelectedERC20Address() public view returns (address){
        return _selectedPayTokenAddress;
    }

    /**
     * @dev get support nft list
     */
    function getSupportNFTToken(
        address _nftAddress
    ) external view returns (Token memory) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        return nftToken.nftToken;
    }
    /**
     * @dev get support payment token list
    */
    function getSupportPaymentToken(
        address _nftAddress
    ) external view returns (Token memory) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        return nftToken.paymentToken;
    }
    /**
     * @dev get support market place token list
    */
    function getSupportMarketPlaceToken(
        address _nftAddress
    ) external view returns (address) {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        return nftToken.marketPlaceAddress;
    }
    function setNewMarketPlaceAddress(
        address _newAddress
    ) public onlyDev {
        implementation  = _newAddress;
    }
    /**
     * @dev add new nft to contract
     * The seller must be the dev
     * nftName: display name of nft
     * nftSymbol: nft token symbol
     * nftAddress: nft token address
     */
    function addERC721Token(
        string memory _nftName, 
        string memory _nftSymbol, 
        address _nftAddress,
        string memory _erc20Name, 
        string memory _erc20Symbol, 
        address _erc20Address
    ) external onlyDev {
        
        if(_nftManager[_nftAddress].marketPlaceAddress == address(0)){
            supportNFTs.push(_nftAddress);
        }
        _nftManager[_nftAddress].nftToken = Token(_nftName, _nftSymbol, _nftAddress);
        _nftManager[_nftAddress].paymentToken = Token(_erc20Name, _erc20Symbol, _erc20Address);
        _nftManager[_nftAddress].is721 = true;
        createNewMarketPlaceToken(_nftName, _nftAddress, _erc20Address, devAddress, true);
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        selectNFT(_nftAddress);
        emit CyberMarketTokenAdded(
                _nftName,
                _nftSymbol,
                _nftAddress,
                _erc20Name,
                _erc20Symbol,
                _erc20Address,
                nftToken.marketPlaceAddress
        );
    }

    function importExistMarketPlace(
        string memory _nftName, 
        string memory _nftSymbol, 
        address _nftAddress,
        string memory _erc20Name, 
        string memory _erc20Symbol, 
        address _erc20Address,
        address _marketPlaceAddress,
        bool isSupportERC721
    ) external onlyDev {
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        require(
            nftToken.marketPlaceAddress != address(0), "This token still not registed."
        );
        _nftManager[_nftAddress].nftToken = Token(_nftName, _nftSymbol, _nftAddress);
        _nftManager[_nftAddress].paymentToken = Token(_erc20Name, _erc20Symbol, _erc20Address);
        _nftManager[_nftAddress].marketPlaceAddress = _marketPlaceAddress;
        _nftManager[_nftAddress].is721 = isSupportERC721;
        selectNFT(_nftAddress);
        emit CyberMarketTokenAdded(
                _nftName,
                _nftSymbol,
                _nftAddress,
                _erc20Name,
                _erc20Symbol,
                _erc20Address,
                _marketPlaceAddress
        );
    }
    /**
     * @dev add new nft to contract
     * The seller must be the dev
     * nftName: display name of nft
     * nftSymbol: nft token symbol
     * nftAddress: nft token address
     */
    function addERC1155Token(
        string memory _nftName, 
        string memory _nftSymbol, 
        address _nftAddress,
        string memory _erc20Name, 
        string memory _erc20Symbol, 
        address _erc20Address
    ) external onlyDev {
        if(_nftManager[_nftAddress].marketPlaceAddress == address(0)){
            supportNFTs.push(_nftAddress);
        }
        _nftManager[_nftAddress].nftToken = Token(_nftName, _nftSymbol, _nftAddress);
        _nftManager[_nftAddress].paymentToken = Token(_erc20Name, _erc20Symbol, _erc20Address);
        _nftManager[_nftAddress].is721 = false;
        createNewMarketPlaceToken(_nftName, _nftAddress, _erc20Address, devAddress, false);
        NFTToken memory nftToken =  _nftManager[_nftAddress];
        selectNFT(_nftAddress);
        emit CyberMarketTokenAdded(
                _nftName,
                _nftSymbol,
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
        if(nftToken.is721){
            selectNFT721Token(nft.tokenAddress);
        }else{
            selectNFT1155Token(nft.tokenAddress);
        }
        Token memory erc20 = nftToken.paymentToken;
        selectPaymentToken(erc20.tokenAddress);
        address marketToken = nftToken.marketPlaceAddress;
        _selectedMarketPlaceToken = MarketPlaceV2(marketToken);
    }
    /**
     * @dev set active nft to nft address
     * The seller must be the dev
     * _nftAddress: nft token address
    */
    function selectNFT721Token(
        address _nftAddress
    ) private {
        if(_nftAddress != _selectedNftAddress){
            _erc721 = IERC721(_nftAddress);
            _selectedNftAddress = _nftAddress;
        }
    }
    function selectNFT1155Token(
        address _nftAddress
    ) private {
        if(_nftAddress != _selectedNftAddress){
            _erc1155 = IERC1155(_nftAddress);
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
     * @dev create new CyberBoxMarketPlace contract for nft
     * The seller must be the dev
     * _nftName: display name of nft
     * _nftAddress: nft token address
     */
    function createNewMarketPlaceToken(
        string memory _nftName,
        address _nftAddress,
        address _erc20Address,
        address _owner,
        bool isSupportERC721
        ) private {
        
        uint256 newId = atContract.current();
        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementation,
            toBytes(newId)
        );
        _nftManager[_nftAddress].marketPlaceAddress = newContract;
        if(isSupportERC721 == true){
            MarketPlaceV2(newContract).initializeWithERC721(
                _nftName,
                _nftAddress,
                _erc20Address,
                _owner
            );
        }else{
            MarketPlaceV2(newContract).initializeWithERC1155(
                _nftName,
                _nftAddress,
                _erc20Address,
                _owner
            );
        }
        atContract.increment();
    }

    function toBytes(uint256 x)
        private
        view 
        returns (bytes32 b) {
		return bytes32(keccak256(abi.encodePacked(x)));
	}
}