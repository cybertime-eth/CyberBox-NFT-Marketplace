const { expect } = require("chai");
const { BigNumber, ethers } = require("hardhat");

// const { BigNumber, ethers } =  require("ethers");
const bigNum = num => (num + '0'.repeat(18))
const web3 = require("web3");

///// dev: 0xD0841B274231a348d352e0786AFB1632A21B7705
///// market: 0xa8EE8563081F764b471C3C57A1e18f7507ca4A5D
//// marketMain: 0x6575e9e5eC3d000CdcE68FC3236dC4AEe6e93b71
//// ERC721: 0x784Fc06C506B6C680c65d425222831Aa0AE7052b
//// daos: 0xd72F0884eC13673a86D28686539e1cCF34de5c51


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
            this.dbilia,
            this.dev,
            this.team,
            ...addrs
        ] = await ethers.getSigners();

        this.TestERC20 = await ethers.getContractFactory("TestERC20");
        this.SecERC20 = await ethers.getContractFactory("SecondERC20");
        this.NFT721 = await ethers.getContractFactory("NFT1155");
        this.MarketPlaceV2 = await ethers.getContractFactory("MarketPlaceV2");
        this.CyberBoxMarketplace = await ethers.getContractFactory("CyberBoxMarketplace");

        this.paymentToken = await this.TestERC20.deploy();
        console.log("Deployed: TestERC20");
        this.secondPaymentToken = await this.SecERC20.deploy();
        console.log("Deployed: SecERC20");
        this.nft721 = await this.NFT1155.deploy("https://google.com");
        console.log("Deployed: NFT1155");
        this.marketPlace = await this.MarketPlaceV2.deploy();
        console.log("Deployed: MarketPlaceV2");
        this.marketMain = await this.CyberBoxMarketplace.deploy(this.owner.address, this.owner.address, this.marketPlace.address);
        console.log("Deployed: CyberBoxMarketplace");

        const accounts = [this.alice_0, this.alice_1, this.alice_2, this.alice_3, this.alice_4, this.alice_5];
        this.paymentToken.approve(this.owner.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.owner.address, "10000000000000000000000000000");
        this.paymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        this.secondPaymentToken.approve(this.marketMain.address, "10000000000000000000000000000");
        
        for (let i = 0; i < 6; i++) {
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
});