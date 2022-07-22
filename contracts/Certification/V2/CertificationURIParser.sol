// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "hardhat/console.sol";

contract CertificationURIParser {
    function substring(string memory str, uint startIndex, uint endIndex) private returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function strLen(string memory s) private returns (uint256) {
        return bytes(s).length;
    }

    function compareStrings(string memory a, string memory b) private returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function strToUint(string memory _str) private returns(uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0, false);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return (res, true);
    }
    
    function parsingTokenURI(string memory _url, string memory baseURI) public returns (uint256, uint256, uint256) {
        uint256 tokenType;
        uint256 year;
        uint256 month;
        string memory parsedString = substring(_url, strLen(baseURI) + 1, strLen(_url));
        string memory typeStr = substring(parsedString, 0, 1);
        string memory yearStr = substring(parsedString, 1, 5);
        (uint256 _year, bool success) = strToUint(yearStr);
        year = _year;
        if(compareStrings(typeStr, "m") == true){
            tokenType = 0;
            string memory monthStr = substring(parsedString, 5, 6);
            (uint256 _month, bool success) = strToUint(monthStr);
            month = _month;
        }else if(compareStrings(typeStr, "y") == true){
            tokenType = 1;
        }else{
            tokenType = 2;
        }
        return (tokenType, year, month);
    }
}
