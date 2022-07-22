// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "hardhat/console.sol";

contract CyberBoxCertNFT is ERC721URIStorage  {

    address public dev;
    address public owner;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    CountersUpgradeable.Counter private atEditionId;

    constructor(
        address _owner,
        address _dev
    ) public ERC721("CyberBoxCertNFT", "CBCN") {
        owner = _owner;
        dev = _dev;
    }

    function mintNFT(address _recipient, string memory _tokenURI) public onlyDev returns (uint256) {
        atEditionId.increment();
        uint256 tokenId = atEditionId.current();
        _mint(_recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        return (tokenId);
    }

    function burn(address _recipient, uint256 tokenId) public onlyDev {
        require(_isApprovedOrOwner(_recipient, tokenId), "Not approved");
        _burn(tokenId);
    }

    function changeDev(address _newDev) public onlyDev {
        dev  = _newDev;
    }

    modifier onlyDev() {
        require((msg.sender == dev || msg.sender == owner), "CyberBoxCertNFT: wrong developer");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}