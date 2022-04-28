// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MarketPlaceFeeAPI {

    using SafeMath for uint256;

    uint256 private _baseFeeTokenSeller;
    uint256 private _baseFeeTokenProducer;
    uint256 private _baseFeeTokenCreater;
    uint256 private _baseFeeTokenDev;
    uint256 private _baseFeeFraction;
    uint256 private _baseFeeTokenBase;

    address public maketPlaceFeeAddress;
    address public nftCreaterAddress;
    address public nftProducerAddress;

    function initializeFee(
        address _owner
    ) public {
        _baseFeeTokenSeller = 975;
        _baseFeeTokenProducer = 0;
        _baseFeeTokenCreater = 0;
        _baseFeeTokenDev = 25;
        _baseFeeFraction = 25;
        _baseFeeTokenBase = 1000;

        maketPlaceFeeAddress = _owner;
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
    function serviceFee(address nftAddress) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
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
    function setNFTFees(
        address _nftAddress,
        uint256 _feeCreater,
        uint256 _feeProducer
        )
        external
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

    function setMaketPlaceAddressAndDevFee(
        address _nftAddress,
        address _maketPlaceFeeAddress, 
        uint256 _maketPlaceFeePercentage)
        external
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

    function setTokenCreaterAddress(
        address _nftAddress,
        address _tokenCreaterAddress)
        external
    {
        require(_tokenCreaterAddress != address(0), "Can't set to address 0x0");
        require(
            1000 == _baseFeeTokenBase, "This token is not registed"
        );
        nftCreaterAddress = _tokenCreaterAddress;
    }

    function setTokenProducerAddress(
        address _nftAddress,
        address _tokenProducerAddress)
        external
    {
        require(_tokenProducerAddress != address(0), "Can't set to address 0x0");
        require(
            1000 == _baseFeeTokenBase, "This token is not registed"
        );
        nftProducerAddress = _tokenProducerAddress;
    }

    function changeTokenCreaterAddress(
        address _nftAddress,
        address _tokenCreaterAddress) external {
        nftCreaterAddress = _tokenCreaterAddress;
    }

}