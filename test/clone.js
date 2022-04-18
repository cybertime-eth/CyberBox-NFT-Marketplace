const { expect } = require("chai");
const { BigNumber, ethers } = require("hardhat");

// const { BigNumber, ethers } =  require("ethers");
const bigNum = num => (num + '0'.repeat(18))
const web3 = require("web3");

const getUnixTimeNowInSec = () => Math.floor(Date.now() / 1000);
const getUnixTimeAfterMins = (mins) =>
  getUnixTimeNowInSec() + mins * 60;
const getUnixTimeAfterDays = (days) =>
  getUnixTimeNowInSec() + days * 60 * 60 * 24;


  
//   dev: 0xFA3A9aBAcC5A5de957f70de245026DcDeFc7e3Ee
//   daos: 0x34d63dc2f8c5655bA6E05124B3D4a283A402CEd9
//   maos: 0x1FBB74537Bf8b8bbd2aF43fE2115638A67137D45
//   TestERC20: 0x37dBEEc3751de85E2fcF1Ffb4e846989E0B92a8c
//   SecondERC20: 0x2BE95cD2A0c221267fA298a6c45F8FB8Bfe7834A
//   CyberBoxMarket: 0x31C55495677e1162844d30f1C08f9CB3cA0c4CC6
//   MarketMain: 0x0EE7dd659d273408957cbEF517f06853E1D9Ce2d


/////// main net

/// dev: 0xceaA07Df0280FbD291AE4ce7AAA7c8672DFB7542
/// daos: 0xed414B42986DEc25D47549f681869A976dC85422
/// marketPlace: 0x78253a54a7FD429605E8815f96EedB91c92073e0
/// marketMain: 0x1c39c7ef3FbEFEc96e1E6563Fd8270f27C00c232

  describe("CyberBoxMaketPlace", function () {
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
            this.dbilia,
            this.dev,
            this.team,
            ...addrs
        ] = await ethers.getSigners();

        this.TestERC20 = await ethers.getContractFactory("TestERC20");
        this.SecERC20 = await ethers.getContractFactory("SecondERC20");
        this.Daos = await ethers.getContractFactory("Daos");
        this.Maos = await ethers.getContractFactory("Maos");
        this.CyberBoxMarketPlace = await ethers.getContractFactory("CyberBoxMarket");
        this.MarketMain = await ethers.getContractFactory("MarketMain");
        

        this.paymentToken = await this.TestERC20.deploy();
        console.log("Deployed: TestERC20");
        this.secondPaymentToken = await this.SecERC20.deploy();
        console.log("Deployed: SecERC20");
        this.daos = await this.Daos.deploy(this.owner.address);
        console.log("Deployed: Daos");
        this.maos = await this.Maos.deploy(this.owner.address);
        console.log("Deployed: maos");
        this.marketplaceInstance = await this.CyberBoxMarketPlace.deploy();
        console.log("Deployed: CyberBoxMarketPlace");
        this.marketMain = await this.MarketMain.deploy(this.owner.address, this.owner.address, this.marketplaceInstance.address);
        console.log("Deployed: MarketMain");

        const accounts = [this.alice_0, this.alice_1, this.alice_2, this.alice_3, this.alice_4, this.alice_5];

        console.log("total supply", parseInt(await this.paymentToken.totalSupply(), 10));
        this.paymentToken.approve(this.owner.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.owner.address, "10000000000000000000000000000");

        this.paymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        //10000000000000000000000000000
        //1100000000000000000
        // Mint payment tokens
        for (let i = 0; i < 6; i++) {

          await this.paymentToken.approve(accounts[i].address, "10000000000000000000000000000");
            await this.paymentToken.transfer(accounts[i].address, "1000000000000000000000000000");

            await this.secondPaymentToken.approve(accounts[i].address, "10000000000000000000000000000");
            await this.secondPaymentToken.transfer(accounts[i].address, "1000000000000000000000000000");
        }
        // Mint ERC721 tokens
        await this.daos.startSale();
        const promises = [];
        for (let i = 0; i < TOKEN_SUPPLY; i++) {
            promises.push(this.daos.mint(accounts[i].address, 1));
        }
        await Promise.all(promises);

    });
    it("Should buy token", async function() {
      const str2 = "2000000000000000";
      console.log(str2);
      let new_str_2 = str2.substring(0, str2.length - 15)
      if(new_str_2.length == 0){
        console.log("length:0");
      }
      console.log(new_str_2);
      let valI64_2 = parseInt(new_str_2)
      console.log(valI64_2);

      const str1 = "250000000000000";
      console.log(str1);
      let new_str = str1.substring(0, str1.length - 15)
      if(new_str == null){
        console.log("null");
      }
      if(new_str.length == 0){
        console.log("length:0");
      }
      console.log(new_str);
      let valI64 = parseInt(new_str)
      console.log(valI64);


      const str3 = "100000000000000000";
      console.log(str3);
      let new_str_3 = str3.substring(0, str3.length - 15)
      if(new_str_3.length == 0){
        console.log("length:0");
      }
      console.log(new_str_3);
      let valI64_3 = parseInt(new_str_3)
      console.log(valI64_3);

      // const balanceOf_market_0 = await this.paymentToken.balanceOf(this.marketMain.address);
      // const balanceOf_owner0_0 = await this.paymentToken.balanceOf(this.alice_0.address);
      // const balanceOf_owner2_0 = await this.paymentToken.balanceOf(this.alice_2.address);
      
      //   await this.marketMain.connect(this.owner).addNFTToken(
      //       "daos",
      //       "daos",
      //       this.daos.address,
      //       "Test ERC20",
      //       "T20",
      //       this.paymentToken.address
      //   );
      //   const daos_nftToken = await this.marketMain.getSupportNFTToken(this.daos.address);
      //   const daos_payToken = await this.marketMain.getSupportPaymentToken(this.daos.address);
      //   const daos_marketPlace = await this.marketMain.getSupportMarketPlaceToken(this.daos.address);
        
      //   await this.marketMain.connect(this.owner).setMaketPlaceAddressAndDevFee(
      //       this.daos.address,
      //       this.alice_0.address,
      //       100
      //   );

      //   await this.marketMain.connect(this.owner).addNFTToken(
      //       "maos",
      //       "maos",
      //       this.maos.address,
      //       "SecondERC20",
      //       "S20",
      //       this.secondPaymentToken.address
      //   );


      //   const maos_nftToken = await this.marketMain.getSupportNFTToken(this.maos.address);
      //   const maos_payToken = await this.marketMain.getSupportPaymentToken(this.maos.address);
      //   const maos_marketPlace = await this.marketMain.getSupportMarketPlaceToken(this.maos.address);

      //   await this.marketMain.connect(this.owner).setMaketPlaceAddressAndDevFee(
      //       this.maos.address,
      //       this.alice_1.address,
      //       110
      //   );

      //   await this.marketMain.connect(this.owner).setTokenCreaterAddress(
      //       this.daos.address,
      //       this.alice_2.address
      //   );
      //   await this.marketMain.connect(this.owner).setTokenCreaterAddress(
      //       this.maos.address,
      //       this.alice_2.address
      //   );

      //   await this.marketMain.connect(this.owner).setTokenProducerAddress(
      //       this.daos.address,
      //       this.alice_5.address
      //   );

      //   await this.marketMain.connect(this.owner).setTokenProducerAddress(
      //       this.maos.address,
      //       this.alice_5.address
      //   );

      //   await this.marketMain.connect(this.owner).setNFTFees(
      //       this.daos.address,
      //       20,
      //       20
      //   );
      //   await this.marketMain.selectNFT(this.daos.address);
      //   await this.marketMain.connect(this.owner).setNFTFees(
      //       this.maos.address,
      //       25,
      //       25
      //   );
      //   // const approveReceipt = await this.daos.connect(this.alice_0).approve(this.marketplaceInstance.address, 1);
      //   const approveReceipt = await this.daos.connect(this.alice_0).approve(daos_marketPlace, 1);
      //   const receipt = await this.marketMain.connect(this.alice_0).listToken(
      //       this.daos.address,
      //       1,
      //       1,
      //       getUnixTimeAfterDays(2)
      //   );

      //   await this.daos.connect(this.alice_3).approve(daos_marketPlace, 4);
      //   await this.marketMain.connect(this.alice_3).listToken(
      //         this.daos.address,
      //         4,
      //         1,
      //          getUnixTimeAfterDays(2)
      //     );

      //   const allListings_0 = await this.marketMain.getAllTokenListings();
      //   console.log("allListings- just list", allListings_0);

      //   await network.provider.send("evm_increaseTime", [174000])
      //   await network.provider.send("evm_mine")

      //   const allListings_1 = await this.marketMain.getAllTokenListings();
      //   console.log("allListings - jump time", allListings_1);

      //   let receipt_clean = await this.marketMain.cleanAllInvalidListings(this.daos.address);
      //   receipt_again = await receipt_clean.wait();
      //   console.log("receipt_again", receipt_again);

      //   const allListings_2 = await this.marketMain.getAllTokenListings();
      //   console.log("allListings - after clean", allListings_2);


  //       this.paymentToken.connect(this.alice_2).approve(this.marketMain.address, "10000000000000000000000000000");
  //       await this.marketMain.connect(this.alice_2).enterBidForToken(
  //         this.daos.address,
  //           1,
  //           web3.utils.toWei("1.1"),
  //           getUnixTimeAfterDays(2),
  //           {
  //             value: web3.utils.toWei("1.1"),
  //           }
  //       );

  //       const allTokenBids = await this.marketMain.getTokenBids(
  //         1
  //       );
      
  //     const balanceOf_market = await this.paymentToken.balanceOf(this.marketMain.address);
  //     const balanceOf_owner0 = await this.paymentToken.balanceOf(this.alice_0.address);
  //     const balanceOf_owner2 = await this.paymentToken.balanceOf(this.alice_2.address);
  //     console.log("balanceOf_market_0", balanceOf_market.toString());
  //     console.log("balanceOf_owner0_0", balanceOf_owner0.toString());
  //     console.log("balanceOf_owner2_0", balanceOf_owner2.toString());

  //     await this.marketMain.connect(this.alice_0).acceptBidForToken(
  //       this.daos.address,
  //       1,
  //       this.alice_2.address
  //     );

  //     const balanceOf_market_1 = await this.paymentToken.balanceOf(this.marketMain.address);
  //     const balanceOf_owner0_1 = await this.paymentToken.balanceOf(this.alice_0.address);
  //     const balanceOf_owner2_1 = await this.paymentToken.balanceOf(this.alice_2.address);
  //     console.log("balanceOf_market_1", balanceOf_market_1.toString());
  //     console.log("balanceOf_owner0_1", balanceOf_owner0_1.toString());
  //     console.log("balanceOf_owner2_1", balanceOf_owner2_1.toString());

  //    await this.daos.connect(this.alice_3).approve(daos_marketPlace, 4);
  //    await this.marketMain.connect(this.alice_3).listToken(
  //     this.daos.address,
  //     4,
  //     web3.utils.toWei("1"),
  //      getUnixTimeAfterDays(2)
  // );
  // const allListings = await this.marketMain.getAllTokenListings();
  //       console.log("allListings", allListings);
  // this.paymentToken.connect(this.alice_4).approve(this.marketMain.address, "10000000000000000000000000000");
  //   await this.marketMain.connect(this.alice_4).buyToken(
  //             this.daos.address,
  //             4, 
  //             web3.utils.toWei("1.5"),
  //             {
  //               value: web3.utils.toWei("1.5"),
  //             }
  //   );
  //     const balanceOf_owner3_1 = await this.paymentToken.balanceOf(this.alice_3.address);
  //     const balanceOf_owner4_1 = await this.paymentToken.balanceOf(this.alice_4.address);
  //     console.log("balanceOf_owner3_1", balanceOf_owner3_1.toString());
  //     console.log("balanceOf_owner4_1", balanceOf_owner4_1.toString());

      // this.paymentToken.connect(this.alice_2).approve(this.marketMain.address, "10000000000000000000000000000");
      // const new_receipt = await this.marketMain.connect(this.alice_2).buyToken(
      //         this.daos.address,
      //         1, web3.utils.toWei("1.2")
      //       );

      // await this.marketMain.connect(this.alice_0).acceptBidForToken(
      //   this.daos.address,
      //   1,
      //   this.alice_2.address,
      //   {
      //           value: web3.utils.toWei("1.2"),
      //   }
      // );

      // const balanceOf_owner0_1 = await this.paymentToken.balanceOf(this.alice_0.address);
      // const balanceOf_owner2_1 = await this.paymentToken.balanceOf(this.alice_2.address);
      // console.log("balanceOf_owner0_1", balanceOf_owner0_1.toString());
      // console.log("balanceOf_owner2_1", balanceOf_owner2_1.toString());

      // this.paymentToken.connect(this.alice_2).transfer(this.alice_0.address, web3.utils.toWei("5"));
      

      // const balanceOf_owner0_2 = await this.paymentToken.balanceOf(this.alice_0.address);
      // const balanceOf_owner2_2 = await this.paymentToken.balanceOf(this.alice_2.address);
      // console.log("balanceOf_owner0_1", balanceOf_owner0_2.toString());
      // console.log("balanceOf_owner2_1", balanceOf_owner2_2.toString());

        // console.log("timestamp:", getUnixTimeAfterDays(2).toString());
        // const listing = await this.marketMain.getTokenListing(1);
        // console.log("listing", listing);
        // const allListings = await this.marketMain.getAllTokenListings();
        // console.log("allListings", allListings);
        // const tokenToBuy = allListings[0];
        // console.log("tokenToBuy", tokenToBuy);
        

      //   const new_receipt = await this.marketMain.connect(this.alice_1).buyToken(
      //       this.daos.address,
      //       tokenToBuy.tokenId, {
      //       value: web3.utils.toWei("1.2"),
      //     });
        
      //     console.log("Owner", await this.daos.ownerOf(1))
      //     console.log("alice_1", this.alice_1.address)
    
      //     await this.daos.connect(this.alice_1).approve(daos_marketPlace, 1);
      //     await this.marketMain.connect(this.alice_1).transfer(
      //       this.daos.address,
      //       this.alice_2.address,
      //       1
      //     );
      //     console.log("Owner", await this.daos.ownerOf(1))
      //     console.log("alice_1", this.alice_1.address)
      //     console.log("alice_2", this.alice_2.address)


      //   await this.daos.connect(this.alice_2).approve(daos_marketPlace, 1);
      //   await this.marketMain.connect(this.alice_2).listToken(
      //       this.daos.address,
      //       1,
      //       web3.utils.toWei("1"),
      //        getUnixTimeAfterDays(2)
      //   );
      //   const new_listing = await this.marketMain.getTokenListing(1);
      //   console.log("new_listing", listing);

      //     await this.marketMain.connect(this.alice_2).changePrice(
      //       this.daos.address,
      //       1,
      //       web3.utils.toWei("1.2"),
      //     );

      //   await this.marketMain.selectNFT(this.daos.address);
      //   console.log("serviceFee_daos", await this.marketMain.serviceFee());
      //   await this.marketMain.selectNFT(this.maos.address);
      //   console.log("serviceFee_maos", await this.marketMain.serviceFee());


      //   await this.marketMain.connect(this.owner).changeERC20Token(
      //     this.daos.address,
      //     "SecondERC20",
      //       "S20",
      //       this.secondPaymentToken.address
      // );
      //   const _nftToken = await this.marketMain.getSupportNFTToken(this.daos.address);
      //   const _payToken = await this.marketMain.getSupportPaymentToken(this.daos.address);
      //   const _marketPlace = await this.marketMain.getSupportMarketPlaceToken(this.daos.address);
        
      //   console.log("nftToken", _nftToken);
      //   console.log("payToken", _payToken);
      //   console.log("daos_marketPlace", _marketPlace);

    });
    
});
