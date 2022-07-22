const { expect } = require("chai");
const { BigNumber, ethers } = require("hardhat");

// const { BigNumber, ethers } =  require("ethers");
const bigNum = num => (num + '0'.repeat(18))
const web3 = require("web3");


/* TEST NET
Owner: 0x8b2f369379C6CCFeC432e34D435712616666963A
Dev: 0xc09cF233d40c8cf66623b3Cf9B933230350915aF
NFT: 0x033B2baf4a2A05Ee77415fB9C144D29DB9B6107e
https://alfajores-blockscout.celo-testnet.org/address/0x033B2baf4a2A05Ee77415fB9C144D29DB9B6107e/contracts
V1: 0x488937D9cB4d8E04b04281EA20ec207A87744Fc3
https://alfajores-blockscout.celo-testnet.org/address/0x488937D9cB4d8E04b04281EA20ec207A87744Fc3/write-contract
V2: 0x7e7e0F9a9927512969a07A288F59797a36715792
https://alfajores-blockscout.celo-testnet.org/address/0x7e7e0F9a9927512969a07A288F59797a36715792/contracts
IPFS: https://cybertime.mypinata.cloud/ipfs/QmRP5KjMDtohsTcXPWtphfVATcMWADeTN7ea3NE131njFu

*/


describe("Support1155", function () {
    before(async function () {
        
        [
            this.owner,
            this.alice_0,
            this.alice_1,
            this.alice_2,
            this.alice_3,
            this.alice_4,
            this.alice_5,
            this.me,
            this.dev,
            this.carbon,
            this.team,
            ...addrs
        ] = await ethers.getSigners();

        this.CyberboxNFT = await ethers.getContractFactory("CyberBoxCertNFT");
        this.ownNFT = await this.CyberboxNFT.deploy(this.owner.address, this.dev.address);
        console.log("Deployed: ownNFT");

        this.CyberboxMinter = await ethers.getContractFactory("CyberBoxCertMinter");
        this.certNFT = await this.CyberboxMinter.deploy(
            this.ownNFT.address, this.dev.address, this.owner.address, this.carbon.address);
        console.log("Deployed: certNFT");


        this.CyberboxMinterV2 = await ethers.getContractFactory("CyberBoxCertMinterV2");
        this.certNFTV2 = await this.CyberboxMinterV2.deploy(
            this.ownNFT.address, this.dev.address, this.owner.address, this.carbon.address);
        console.log("Deployed: certNFTV2");

        this.CertificationURIParser = await ethers.getContractFactory("CertificationURIParser");
        this.utility = await this.CertificationURIParser.deploy()
        console.log("Deployed: utility");
    });

    it("Support CyberTimeCertNFT", async function() {
        
        const baseURI = "http://ipfs/ewiowwer4823423kljl";

        await this.ownNFT.connect(this.owner).changeDev(this.certNFT.address);
        await this.certNFT.connect(this.dev).setBaseURI(baseURI);
        
        await this.certNFT.connect(this.alice_0).mintMonthNFT({
            value: ethers.utils.parseEther("15")
        })
        await this.certNFT.connect(this.alice_1).mintMonthNFT({
            value: ethers.utils.parseEther("15")
        })
        await this.certNFT.connect(this.alice_2).mintMonthNFT({
            value: ethers.utils.parseEther("15")
        })
        console.log("mint month");
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 1)
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 2)
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 3)
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 4)
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 5)
        await this.certNFT.connect(this.dev).adminMintMonthlyNFT(this.alice_0.address, 6)
        console.log("mint admin month");
        
        await this.ownNFT.connect(this.alice_0).setApprovalForAll(this.certNFT.address, true);
        await this.ownNFT.connect(this.alice_1).setApprovalForAll(this.certNFT.address, true);
        await this.ownNFT.connect(this.alice_2).setApprovalForAll(this.certNFT.address, true);

        await this.certNFT.connect(this.alice_0).ListToken(1, 1)
        await this.certNFT.connect(this.alice_1).ListToken(2, 1)
        await this.certNFT.connect(this.alice_2).ListToken(3, 1)

        await this.certNFTV2.connect(this.dev).setBaseURI(baseURI);
        await this.certNFTV2.connect(this.dev).restoreFromV1(this.certNFT.address);
        console.log("restoreFromV1");
        console.log("restoreNFTs-1");
        await this.certNFTV2.connect(this.dev).restoreNFTs(9);
        console.log("restoreNFTs-2");
        await this.certNFTV2.connect(this.dev).restoreNFTs(9);
        

        await this.certNFTV2.getCurrentMonthNFTID(this.alice_0.address);
        await this.certNFTV2.getCurrentMonthNFTID(this.alice_1.address);
        await this.certNFTV2.getCurrentMonthNFTID(this.alice_2.address);
        await this.certNFTV2.getMonthNFTID(this.alice_0.address, 2022, 1);
        await this.certNFTV2.getMonthNFTID(this.alice_0.address, 2022, 6);
        

        await this.ownNFT.connect(this.alice_0).setApprovalForAll(this.certNFTV2.address, true);
        await this.ownNFT.connect(this.alice_1).setApprovalForAll(this.certNFTV2.address, true);
        await this.ownNFT.connect(this.alice_2).setApprovalForAll(this.certNFTV2.address, true);

        await this.certNFTV2.connect(this.alice_0).ListToken(1, 1)
        await this.certNFTV2.connect(this.alice_1).ListToken(2, 1)
        await this.certNFTV2.connect(this.alice_2).ListToken(3, 1)

        await this.ownNFT.connect(this.owner).changeDev(this.certNFTV2.address);
        console.log("mintMonthNFTFromRefer");
        await this.certNFTV2.connect(this.alice_4).mintMonthNFTFromRefer(
            this.alice_0.address,
            {
                value: ethers.utils.parseEther("15")
            }
        );

        await this.certNFTV2.getCurrentMonthNFTID(this.alice_4.address);

        await this.certNFTV2.connect(this.alice_5).mintMonthNFTFromRefer(
            this.alice_1.address,
            {
                value: ethers.utils.parseEther("15")
            }
        );
        await this.certNFTV2.getCurrentMonthNFTID(this.alice_5.address);
    
    });
});