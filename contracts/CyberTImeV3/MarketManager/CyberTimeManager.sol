// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "../MarketMain/CyberBoxMarketplace.sol";
import "../MarketPlace/MarketPlaceV2.sol";
import "./CyberBoxManagerInterface.sol";

contract CyberTimeManager is CyberBoxManagerInterface{

    address public marketMainAddress;
    mapping(address => address) public marketPlaceAddresses;
    address[] public nftAddresses;

    CyberBoxMarketplace private _maketMainContract;

    constructor() public {
    }

    function setMaketMainAddress(address marketMain) public {
        marketMainAddress = marketMain;
        _maketMainContract = CyberBoxMarketplace(marketMainAddress);
    }
    function addNFTAddress(address nftAddress) public {
        address marketPlace = marketPlaceAddresses[nftAddress];
        if (marketPlace == address(0)){
            nftAddresses.push(nftAddress);
            address marketPlace = _maketMainContract.getNFTToken(nftAddress).marketPlaceAddress;
            marketPlaceAddresses[nftAddress] = marketPlace;
        }
    }

    function getMarketPlaceAddress(address nftAddress) public returns(address){
        return marketPlaceAddresses[nftAddress];
    }

    function cleanInvalidLists(address nftAddress) public returns (uint256[] memory){
        address marketPlaceV2Add = getMarketPlaceAddress(nftAddress);
        MarketPlaceV2 marketPlaceContract =  MarketPlaceV2(marketPlaceV2Add);
        (uint256[] memory idList) =  marketPlaceContract.cleanAllInvalidListings();
        for (uint256 i = 0; i < idList.length; i++) {
            uint256 contract_id = idList[i];
            emit CyberBoxManagerDelisted(
                nftAddress,
                contract_id
            );
        }
    }

    function cleanAllContracts(uint256 from, uint256 count) public {
        for (uint256 i = 0; i <= count; i++) {
            uint256 indexing = i + from;
            if (nftAddresses.length > indexing){
                address nftAddress = nftAddresses[i];
                (uint256[] memory idList) = cleanInvalidLists(nftAddress);
                for (uint256 i = 0; i < idList.length; i++) {
                    uint256 contract_id = idList[i];
                    emit CyberBoxManagerDelisted(
                        nftAddress,
                        contract_id
                    );
                }
            }
        }
    }

    function checkListValidation(address nftAddress, uint256 contractId) public returns (bool){
        address marketPlaceV2Add = getMarketPlaceAddress(nftAddress);
        MarketPlaceV2 marketPlaceContract =  MarketPlaceV2(marketPlaceV2Add);
        InterfaceV2.Listing memory listing = marketPlaceContract.getTokenListing(contractId);
        if (listing.seller == address(0)){
            emit CyberBoxManagerDelisted(
                nftAddress,
                contractId
            );
            return false;
        }
        return true;
    }
}