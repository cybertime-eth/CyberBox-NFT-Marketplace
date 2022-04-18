// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CeloShapes is ERC721Enumerable, Ownable {

    event DaosMinted(
        uint id, 
        uint price,
        address seller,
        address owner,
        string attributes,
        uint rarity_rank,
        address contract_address,
        string market_status);

    using Strings for uint256;
    using SafeMath for uint256;
    using Address for address;

    uint public MAX_DAOS = 9192;
    bool public hasSaleStarted = false;

    string public baseURI;
    string public baseExtension=".json";

    address public dev; // developer address

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }

    constructor(
        address _dev
        ) ERC721("CeloShapes", "cshape") public {
        dev = _dev;
        setBaseURI("https://ipfs.io/ipfs/QmX1A8ekGH8u4Bo8RTviPSmEYLWGaPj6jFnixLX9oKo3pf/");
    }

    //internal
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
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
        if (currentSupply >= 9001) {
            return 50000000000000000000;
            // 9001-9192:  50 CELO
        } else if (currentSupply >= 8001) {
            return 30000000000000000000;
            // 8000-9000:  30 CELO
        }else if (currentSupply >= 6001) {
            return 20000000000000000000;
            // 6000-8000:  20 CELO
        }else if (currentSupply >= 4001) {
            return 15000000000000000000;
            // 4000-6000:  15 CELO
        } else if (currentSupply >= 2751) {
            return 10000000000000000000;
            // 2750-4000:   10 CELO
        } else if (currentSupply >= 2251) {
            return 5000000000000000000;
            // 2250-2750:   5 CELO
        }else if (currentSupply >= 2001) {
            return 2000000000000000000;
            // 2000-2250:   2 CELO
        } else {
            return 0;
            // 0 - 2000     Free
        }
    }
    //public
    function mint(address _to, uint256 _mintAmount) public payable{
        uint256 supply =totalSupply();
        require(totalSupply() < MAX_DAOS, "Sale has already ended");
        require(_mintAmount > 0 && _mintAmount <= 100, "You can adopt minimum 1, maximum 100 daos");
        require(totalSupply().add(_mintAmount) <= MAX_DAOS, "Exceeds MAX_DAOS");
        require(msg.value >= calculatePrice().mul(_mintAmount), "BNB value sent is below the price");

        if(dev != address(0) && msg.value > 0){
            Address.sendValue(payable(dev), msg.value);
        }
        
        for(uint256 i=1;i<=_mintAmount;i++){
            uint256 tokenId = supply+i;
            _safeMint(_to, tokenId);
            emit DaosMinted(
                tokenId,            /// token id
                msg.value,          /// price
                msg.sender,         /// seller
                _to,                /// owner
                tokenURI(tokenId),  /// attributes
                0,                  /// rarity_rank
                address(this),      /// contract_address
                "MINT"              /// market_status
            );
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI=_newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner{
        baseExtension=_newBaseExtension;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
        {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token"
            );
            string memory curretBaseURI=_baseURI();
            return bytes(curretBaseURI).length>0
            ? string(abi.encodePacked(curretBaseURI, tokenId.toString(), baseExtension))
            : "";
        }
    function walletOfOwner(address _owner)
        public
        view
        returns(uint256[] memory)
        {
            uint256 ownerTokenCount=balanceOf(_owner);
            uint256[] memory tokenIds=new uint256[](ownerTokenCount);
            for(uint256 i;i<ownerTokenCount;i++){
                tokenIds[i]=tokenOfOwnerByIndex(_owner, i);
            }
            return tokenIds;
        }

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
        require(numDaos > 0 && numDaos <= 100, "Max 50 to reserve at once");
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

