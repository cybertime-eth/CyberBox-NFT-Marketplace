// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.3;

import "./Uniswap/uniswpv2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC777} from "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract CyberBurnTest {

    address public CARBOM = 0x32A9FE697a32135BFd313a6Ac28792DaE4D9979d;
    address private constant UNISWAP_V2_ROUTER = 0xE3D8bd6Aed4F159bc8000a9cD47CffDb95F96121;
    address private constant WETH = 0x471EcE3750Da237f93B8E339c536989b8978a438;

    constructor(
    ) public {
    }

    function uniwapCarbon(uint256 _amountIn) public returns (uint256[] memory amounts){
        IERC20(WETH).approve(UNISWAP_V2_ROUTER, _amountIn);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = CARBOM;
        return IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp);
    }

    function mintMonthNFT() external payable {
        uint256[] memory amounts = uniwapCarbon(msg.value);
        uint256 co2Value = amounts[amounts.length - 1];

        require(ERC777(CARBOM).balanceOf(address(this)) >= co2Value, 'amount exceeds the token balance');

        ERC777(CARBOM).approve(address(this), co2Value);
        ERC777(CARBOM).send(address(0), co2Value, "");
    }
}