// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract CyberTimeCertResource {

    string public baseURI;

    function setBaseURI(string memory _uri) public {
        baseURI = _uri;
    }

    function numberToString(uint256 value)
        public
        pure
        returns (string memory)
    {
        return StringsUpgradeable.toString(value);
    }

    

    function getMonthTokenURI(uint256 year, uint256 month) public returns (string memory) {
        return string(
            abi.encodePacked(
                    baseURI,
                    "/m",
                    numberToString(year),
                    numberToString(month),
                    ".json"
                )
            );
    }
    function getYearTokenURI(uint256 year) public returns (string memory) {
        return string(
            abi.encodePacked(
                    baseURI,
                    "/y",
                    numberToString(year),
                    ".json"
                )
            );
    }
    function getBonusTokenURI(uint256 year) public returns (string memory) {
        return string(
            abi.encodePacked(
                    baseURI,
                    "/b",
                    numberToString(year),
                    ".json"
                )
            );
    }

}