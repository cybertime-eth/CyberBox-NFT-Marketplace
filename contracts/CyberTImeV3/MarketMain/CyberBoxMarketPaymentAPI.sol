// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CyberBoxMarketPaymentAPI {
    using Address for address;

    constructor() public {}

    /**
     * @dev payment from sender to receiver with Custom ERC20 or Celo
     * @param paymentToken payment ERC20
     * @param sender payment from address
     * @param receiver payment to address
     * @param value payment amount
    */
    function sendERC20(
        IERC20 paymentToken,
        address sender,
        address receiver,
        uint256 value
        )  public {
        
        if(isEtherToken(address(paymentToken)) == true){
            transferCelo(sender, receiver, value);
        }else{
            transferERC20(paymentToken, sender, receiver, value);
        }
    }

    /**
     * @dev returns ERC20 is celo token or not
     * @param paymentToken payment token address
    */
    function isEtherToken(address paymentToken) public returns (bool){
        if(paymentToken == address(0x471EcE3750Da237f93B8E339c536989b8978a438) ||
        paymentToken == address(0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9)){
            return true;
        }
        return false;
    }
    /**
     * @dev payment from sender to receiver with Custom ERC20
     * @param paymentToken payment ERC20
     * @param sender payment from address
     * @param receiver payment to address
     * @param value payment amount
    */
    function transferERC20(IERC20 paymentToken, address sender, address receiver, uint256 value) private{
        require(sender != address(0), "transfer address must not 0x0");
        require(receiver != address(0), "transfer address must not 0x0");
        require(value > 0, "transfer amount must large than 0");
        if(sender == address(this)){
            paymentToken.transfer(receiver, value);
        }else{
            paymentToken.transferFrom(sender, receiver, value);
        }
    }
    /**
     * @dev payment from sender to receiver with Celo
     * @param sender payment from address
     * @param receiver payment to address
     * @param value payment amount
    */
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