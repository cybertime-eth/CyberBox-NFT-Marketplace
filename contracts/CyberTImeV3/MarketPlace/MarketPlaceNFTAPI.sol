// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

contract MarketPlaceNFTAPI {
    address public dev; // developer address

    string private _erc721Name;
    IERC721 private _erc721;
    string private _erc1155Name;
    IERC1155 private _erc1155;
    address private _selectedNftAddress;
    address private _selectedERC20Address;
    IERC20 private _paymentToken;

    bool private isSupport1555;

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }
    function changeDev(address _newDev) public onlyDev {
        dev  = _newDev;
    }
    
    function initializeNFTWithERC721(
        string memory erc721Name_,
        address _erc721Address,
        address _paymentTokenAddress
    ) public {
        _erc721Name = erc721Name_;
        _erc721 = IERC721(_erc721Address);
        _selectedNftAddress = _erc721Address;
        _paymentToken = IERC20(_paymentTokenAddress);
        _selectedERC20Address = _paymentTokenAddress;

        dev = msg.sender;
        isSupport1555 = false;
    }
    function initializeNFTWithERC1155(
        string memory erc1155Name_,
        address _erc1155Address,
        address _paymentTokenAddress
    ) public {
        _erc1155Name = erc1155Name_;
        _erc1155 = IERC1155(_erc1155Address);
        _selectedNftAddress = _erc1155Address;
        _paymentToken = IERC20(_paymentTokenAddress);
        _selectedERC20Address = _paymentTokenAddress;

        dev = msg.sender;
        isSupport1555 = true;
    }
    /**
     * @dev check if the account is the owner of this erc721 token
     */
    function _isTokenOwner(uint256 tokenId, address account) public view returns (bool) {
        if(isSupport1555 == false){
            try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
                return tokenOwner == account;
            } catch {
                return false;
            }
        }else{
            return _erc1155.balanceOf(account, tokenId) != 0;
        }
   }
   /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function _isTokenApproved(uint256 tokenId) public view returns (bool) {
        if(isSupport1555 == false){
            try _erc721.getApproved(tokenId) returns (address tokenOperator) {
                return tokenOperator == address(this);
            } catch {
                return false;
            }
        }else{
            return true;
        }
    }
    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function _isAllTokenApproved(address owner) public view returns (bool) {
        if(isSupport1555 == false){
            return _erc721.isApprovedForAll(owner, address(this));
        }else{
            return _erc1155.isApprovedForAll(owner, address(this));
        }
    }

    /**
     * @dev See {INFTKEYMarketPlaceV1-tokenAddress}.
     */
    function nftAddress() external view returns (address) {
        return _selectedNftAddress;
    }
    /**
     * @dev See {INFTKEYMarketPlaceV1-paymentTokenAddress}.
     */
    function paymentTokenAddress() external view returns (address) {
        return _selectedERC20Address;
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
        if(isSupport1555 == false){
            _erc721.safeTransferFrom(sender, to, tokenId);
        }else{
            bytes memory data = '0x0';
            _erc1155.safeTransferFrom(sender, to, tokenId, 1, data);
        }
        
    }

    function nftTransferFrom(
        address sender,
        address to,
        uint256 tokenId
    ) public onlyDev {
        if(isSupport1555 == false){
            _erc721.safeTransferFrom(sender, to, tokenId);
        }else{
            bytes memory data = '0x0';
            _erc1155.safeTransferFrom(sender, to, tokenId, 1, data);
        }
    }

}