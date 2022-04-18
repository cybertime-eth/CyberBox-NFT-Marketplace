const { expect } = require("chai");
const { BigNumber, ethers } = require("hardhat");

// const { BigNumber, ethers } =  require("ethers");
const bigNum = num => (num + '0'.repeat(18))
const web3 = require("web3");

/////// dev: 0xFA3A9aBAcC5A5de957f70de245026DcDeFc7e3Ee
/////// ERC721: 0xBAD212a3b828B1fC28e3D0357D179cA32Cd21402
/////// ERC1155: 0x18cbEEE76c8dA6846Cd1ccB29c74B0b1036edeC3
/////// ERC20_0: 0x0B7f2f500abD0Be18D38855E3Aa07F354132Abe5
/////// ERC20_1: 0xb8601829Af997567dD058811e4359bBBecf0F67B
/////// MarketPlaceV2: 0x355DB79a3d3A7F5a9DcB30aB8303e02C4deE3940
/////// CyberBoxMarketplace: 0x1aFedC8D8a4ACE7516266F1081EFD26a81a8095f


/////// dev: 0xceaA07Df0280FbD291AE4ce7AAA7c8672DFB7542
/////// marketplace: 0x4A7c170C18F77983b23e9a7bE9327aA9F6455796
////// cyberboxmarket: 0xaBb380Bd683971BDB426F0aa2BF2f111aA7824c2
////// Cybertimemanager: 0x37D464ce15D2459F4D88acAC1a54C5599c15d521
// Daopolis - 0xc4ea80deCA2415105746639eC16cB0cF8378996A
// DimsOfCelo - 0x3456eeBb93BDF66Af90115326A55988aa04C7A0B
// CeloToadz - 0x6Fc1C8d59FdC261c55273f9b8e64B7E88C45E208
// CeloPunks - 0x9f46B8290A6D41B28dA037aDE0C3eBe24a5D1160
// CeloPunksNeon - 0x07b6C9D6bB32655A70D97a38a9274da349A1EFAf
// CeloPunks Christmas Edition - 0x0C69fAb99e51b6C2e4a1cAE49B123bbbe94a56cD
// Nomstranaut - 0x11E3f251EE1a4C989c2f39C0041312C18ae780e1
// CeloShapes - 0x501F7Ea7B1aA25fF7D2feB3a2e96979ba754204B
// CeloApes - 0x1eCD77075F7504bA849d47DCe4cdC9695f1FE942

describe("Support1155", function () {
    const TOKEN_SUPPLY = 5;

    before(async function () {
        [
            this.owner,
            this.alice_0,
            this.alice_1,
            this.alice_2,
            this.alice_3,
            this.alice_4,
            this.alice_5,
            this.alice_6,
            this.dbilia,
            this.dev,
            this.team,
            ...addrs
        ] = await ethers.getSigners();

        this.TestERC20 = await ethers.getContractFactory("TestERC20");
        this.SecERC20 = await ethers.getContractFactory("SecondERC20");
        this.NFT1155 = await ethers.getContractFactory("NFT1155");
        this.MarketPlaceV2 = await ethers.getContractFactory("MarketPlaceV2");
        this.CyberBoxMarketplace = await ethers.getContractFactory("CyberBoxMarketplace");

        this.paymentToken = await this.TestERC20.deploy();
        console.log("Deployed: TestERC20");
        this.secondPaymentToken = await this.SecERC20.deploy();
        console.log("Deployed: SecERC20");
        this.nft1155 = await this.NFT1155.deploy("https://google.com");
        console.log("Deployed: NFT1155");
        this.marketPlace = await this.MarketPlaceV2.deploy();
        console.log("Deployed: MarketPlaceV2");
        this.marketMain = await this.CyberBoxMarketplace.deploy(this.owner.address, this.owner.address, this.marketPlace.address);
        console.log("Deployed: CyberBoxMarketplace");

        const accounts = [this.alice_0, this.alice_1, this.alice_2, this.alice_3, this.alice_4, this.alice_5, this.alice_6];
        this.paymentToken.approve(this.owner.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.owner.address, "10000000000000000000000000000");
        this.paymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        
        for (let i = 0; i < 7; i++) {
            await this.paymentToken.approve(accounts[i].address, "10000000000000000000000000000");
            await this.paymentToken.transfer(accounts[i].address, "1000000000000000000000000000");
            await this.secondPaymentToken.approve(accounts[i].address, "10000000000000000000000000000");
            await this.secondPaymentToken.transfer(accounts[i].address, "1000000000000000000000000000");
        }

        // Mint ERC1155 tokens
        const promises = [];
        for (let i = 0; i < TOKEN_SUPPLY; i++) {
            promises.push(this.nft1155.mint(accounts[i].address, i+1, 1));
        }
        await Promise.all(promises);
    });
    it("Support NFT1155", async function() {
        await this.marketMain.connect(this.owner).addERC1155Token(
                  "NFT1155",
                  "1155",
                  this.nft1155.address,
                  "Test ERC20",
                  "T20",
                  this.paymentToken.address
        );
        const N1155_nftToken = await this.marketMain.getSupportNFTToken(this.nft1155.address);
        console.log("N1155_nftToken:", N1155_nftToken);
        const N1155_payToken = await this.marketMain.getSupportPaymentToken(this.nft1155.address);
        console.log("N1155_payToken:", N1155_payToken);
        const N1155_marketPlace = await this.marketMain.getSupportMarketPlaceToken(this.nft1155.address);
        console.log("N1155_marketPlace:", N1155_marketPlace);

        await this.marketMain.connect(this.owner).setMaketPlaceAddressAndDevFee(this.nft1155.address,this.alice_1.address,10);
        await this.marketMain.connect(this.owner).setTokenCreaterAddress(this.nft1155.address,this.alice_2.address);
        await this.marketMain.connect(this.owner).setTokenProducerAddress(this.nft1155.address,this.alice_3.address);await this.marketMain.connect(this.owner).setNFTFees(
                  this.nft1155.address,
                  20,
                  30
        );
        await this.marketMain.connect(this.alice_0).listToken(
                this.nft1155.address,
                1,
                web3.utils.toWei("1")
        );
        const allListings = await this.marketMain.getAllTokenListings();
       
        await this.paymentToken.connect(this.alice_4).approve(this.marketMain.address, "10000000000000000000000000000");

        await this.nft1155.connect(this.alice_0).setApprovalForAll(N1155_marketPlace, true);
        const approveForall = await this.nft1155.connect(this.alice_0).isApprovedForAll(this.alice_0.address, N1155_marketPlace);
        console.log("approveForall:", approveForall);
        const isTokenOwner = await this.nft1155.connect(this.alice_0).balanceOf(this.alice_0.address, 1);
        console.log("isTokenOwner:", isTokenOwner);

        // console.log("safeTransferFrom:", await this.nft1155.connect(this.alice_0).safeTransferFrom(this.alice_0.address, this.alice_4.address, 1, 0, '0x00'));
        console.log("alice_0:", this.alice_0.address);
        console.log("marketPlace:", N1155_marketPlace);
        await this.marketMain.connect(this.alice_4).buyToken(
                        this.nft1155.address,
                        1, 
                        web3.utils.toWei("2"),
                        {
                          value: web3.utils.toWei("2"),
                        }
        );

        const balanceOf_market_c_0 = await this.paymentToken.balanceOf(this.marketMain.address);
        console.log("before enter bid:", balanceOf_market_c_0.toString());

        this.paymentToken.connect(this.alice_5).approve(this.marketMain.address, "10000000000000000000000000000");
        await this.marketMain.connect(this.alice_5).enterBidForToken(
                    this.nft1155.address,
                      1,
                      web3.utils.toWei("2"),
                      {
                        value: web3.utils.toWei("2"),
                      }
        );

        const balanceOf_market_c_1 = await this.paymentToken.balanceOf(this.marketMain.address);
        console.log("after enter bid:", balanceOf_market_c_1.toString());

        await this.marketMain.connect(this.alice_5).withdrawBidForToken(
            this.nft1155.address,
            1
        );

        const balanceOf_market_c_2 = await this.paymentToken.balanceOf(this.marketMain.address);
        console.log("after withdraw bid:", balanceOf_market_c_2.toString());

        await this.marketMain.connect(this.alice_5).enterBidForToken(
            this.nft1155.address,
              1,
              web3.utils.toWei("2"),
              {
                value: web3.utils.toWei("2"),
              }
        );
        //2000000000000000000
        //20000000000000000
        //20000000000000000
        //2020000000000000000
        
      const balanceOf_market_a = await this.paymentToken.balanceOf(this.marketMain.address);
      console.log("before accept bid:2", balanceOf_market_a.toString());

        await this.nft1155.connect(this.alice_4).setApprovalForAll(N1155_marketPlace, true);
        await this.marketMain.connect(this.alice_4).acceptBidForToken(
                  this.nft1155.address,
                  1,
                  this.alice_5.address
        );

        const balanceOf_market_b = await this.paymentToken.balanceOf(this.marketMain.address);
        console.log("after accept bid:2", balanceOf_market_b.toString());

        await this.nft1155.connect(this.alice_5).setApprovalForAll(N1155_marketPlace, true);
        await this.marketMain.connect(this.alice_5).transfer(this.nft1155.address, this.alice_0.address, 1);
       
        await this.marketMain.connect(this.owner).cleanAllInvalidBids();
        await this.marketMain.connect(this.owner).cleanAllInvalidListings();

        
      const balanceOf_market_0 = await this.paymentToken.balanceOf(this.marketMain.address);
      console.log("before enter bid", balanceOf_market_0.toString());

        await this.marketMain.connect(this.alice_5).enterBidForToken(
          this.nft1155.address,
            1,
            web3.utils.toWei("2"),
            {
              value: web3.utils.toWei("2"),
            }
      );

      const balanceOf_market_1 = await this.paymentToken.balanceOf(this.marketMain.address);
      console.log("after enter bid", balanceOf_market_1.toString());
     await this.marketMain.connect(this.owner).withdrawERC20(this.paymentToken.address, this.alice_6.address);
    });
});