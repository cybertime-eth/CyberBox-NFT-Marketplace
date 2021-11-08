// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Daos is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    uint public MAX_DAOS = 8640;
    bool public hasSaleStarted = false;

    address public dev; // developer address

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }

    constructor(address _dev) ERC721("Daos", "Daos") public {
        dev = _dev;
        // setBaseURI("https://cybertime.mypinata.cloud/ipfs/QmVbN32xT2NNE6VPjPjd1vmetSiDvs9PhqzF6sS14fqnJU");
    }

    // Get the current tokens of owner
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // The bounding curve, to enable Early adapters to buy cheap, and make money for charity
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_DAOS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 8001) {
            return 15000000000000000000;
            // 8001-8640:  15 CELO
        } else if (currentSupply >= 7001) {
            return 13000000000000000000;
            // 7001-8000:  13 CELO
        } else if (currentSupply >= 5001) {
            return 11000000000000000000;
            // 5001-7000:   11 CELO
        } else if (currentSupply >= 3001) {
            return 9000000000000000000;
            // 3001-5000:   9 CELO
        }else if (currentSupply >= 1641) {
            return 7000000000000000000;
            // 1640-3000:   7 CELO
        } else {
            return 0;
            // 0 - 1640     Free
        }
    }
    function initialMint(address _toAddress) public onlyDev {
        require (totalSupply() == 0, "1640 daos already minted");
        for (uint i = 0; i < 50; i++) {
            _safeMint(_toAddress, i);
        }
    }
    // Adopt your own numDaos on the Binance Smart Chain,
    // Max 20 at once and make sure the right price is used to confirm transaction
    function adoptDaos(uint256 numDaos) public payable {
        require(totalSupply() < MAX_DAOS, "Sale has already ended");
        require(numDaos > 0 && numDaos <= 1000, "You can adopt minimum 1, maximum 20 daos");
        require(totalSupply().add(numDaos) <= MAX_DAOS, "Exceeds MAX_DAOS");
        require(msg.value >= calculatePrice().mul(numDaos), "BNB value sent is below the price");

        for (uint i = 0; i < numDaos; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // Decrease the MAX_DAOS variable only if these items aren't sold.
    // If sale doens't go as in our dreams, then we can increase it's value by this burn
    function burn(uint256 numDaosToBurn) public onlyDev {
        require(numDaosToBurn > 0 && numDaosToBurn <= 1000, "You can only burn a 1 - 1000 at the time");
        uint NewMaxPoopies = MAX_DAOS - numDaosToBurn;
        require(totalSupply() <= NewMaxPoopies, "There NFT's are allready claimed");
        MAX_DAOS = NewMaxPoopies;
    }


    function _baseURI() override internal view virtual returns (string memory)  {
        return "https://cybertime.mypinata.cloud/ipfs/QmVbN32xT2NNE6VPjPjd1vmetSiDvs9PhqzF6sS14fqnJU/";
    }
    // The trick to change the metadata if necessary and have a reveal moment
    // function setBaseURI(string memory baseURI) public onlyOwner {
    //     _setBaseURI(baseURI);
    // }

    // Start Sale, we can start minting!
    function startSale() public onlyDev {
        hasSaleStarted = true;
    }

    // Pause Sale
    function pauseSale() public onlyDev {
        hasSaleStarted = false;
    }

    // For return on investment, charity payouts and future development
    function withdrawAll() public payable onlyDev {
        require(payable(msg.sender).send(address(this).balance));
    }

    // First items can be added to own wallet with this
    function reserveGiveaway(uint256 numDaos) public onlyDev {
        uint currentSupply = totalSupply();
        require(numDaos > 0 && numDaos <= 50, "Max 50 to reserve at once");
        require(totalSupply().add(numDaos) <= MAX_DAOS, "Exceeds MAX_DAOS");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numDaos; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }

    function changeDev(address _newDev) public onlyDev {
        dev  = _newDev;
    }
}