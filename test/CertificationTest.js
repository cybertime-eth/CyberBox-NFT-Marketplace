const { expect } = require("chai");
const { BigNumber, ethers } = require("hardhat");

// const { BigNumber, ethers } =  require("ethers");
const bigNum = num => (num + '0'.repeat(18))
const web3 = require("web3");


/// NFT: 0xAC0BE69ABF9A845631193bd502d9e5373C11f6a1
/// Minter: 0x0980468994F7c9aEB79932D76aE46fA02DaE0FCD
/// Dev: 0x8b2f369379C6CCFeC432e34D435712616666963A
/// Owner: 0xc09cF233d40c8cf66623b3Cf9B933230350915aF
//// CARVON: 0xc09cF233d40c8cf66623b3Cf9B933230350915aF


/// NFT: 0xa3272cD729273e1efD64bE23bBc530fD3876Ae01
/// Minter: 0x0980468994F7c9aEB79932D76aE46fA02DaE0FCD

///// last
// NFT: 0xA4A8E345E1a88EFc9164014BB2CeBd4C2F98E986
// Minter: 0xFEabeFDf5823f36D3918a753aa5962c96E275126
// Minter2: 0x3e7898C98E44bB734f43C60c782e8e7ee8854706

///dev_me: 0x8b2f369379C6CCFeC432e34D435712616666963A
///dev: 0xD48F5935C88009030a231c5904064673f44dD4b3
// owner:0x454b9F80D3eA53000544eB7c9038D4bA8b84c324
// CO2: 0xf7A60Fa2561f50A04cd3f31aA0F1bEDeD0de1175

////IPFS: https://cybertime.mypinata.cloud/ipfs/QmRP5KjMDtohsTcXPWtphfVATcMWADeTN7ea3NE131njFu/m20245.json

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
            this.dbilia,
            this.dev,
            this.team,
            ...addrs
        ] = await ethers.getSigners();

        this.CyberTimeNFT = await ethers.getContractFactory("CyberTimeCertNFT");
        this.ownNFT = await this.CyberTimeNFT.deploy(this.owner.address, this.alice_1.address);
        console.log("Deployed: ownNFT");
        

        this.CyberTimeMinter = await ethers.getContractFactory("CyberTimeCertMinter");
        this.certNFT = await this.CyberTimeMinter.deploy(this.ownNFT.address, this.owner.address, this.owner.address);
        console.log("Deployed: certNFT");
    });

    it("Support CyberTimeCertNFT", async function() {
        
        await this.ownNFT.connect(this.alice_1).changeDev(this.certNFT.address);

        await this.certNFT.connect(this.alice_1).setBaseURI("http://ipfs/ewiowwer4823423kljl");
        await this.certNFT.connect(this.alice_0).mintMonthNFT();
        await this.certNFT.connect(this.alice_0).getMonthNFTID(this.alice_0.address, 2022, 5);

        await this.certNFT.connect(this.alice_0).mintBonusNFT();
        for(let month=1;month<=12;month++){
            await this.certNFT.connect(this.alice_0).getMonthNFTID(this.alice_0.address, 2022, month);
        }


        await this.certNFT.connect(this.alice_0).exchangeBonusNFTToMonth(2022);
        for(let month=1;month<=12;month++){
            await this.certNFT.connect(this.alice_0).getMonthNFTID(this.alice_0.address, 2022, month);
        }
        await this.certNFT.connect(this.alice_0).getBonusNFTID(this.alice_0.address, 2022);
    
        await this.certNFT.connect(this.alice_0).exchangeMonthNFTToBonus(2022);
        await this.certNFT.connect(this.alice_0).getBonusNFTID(this.alice_0.address, 2022);
        for(let month=1;month<=12;month++){
            await this.certNFT.connect(this.alice_0).getMonthNFTID(this.alice_0.address, 2022, month);
        }

        await this.certNFT.connect(this.alice_0).mintYearNFT();
        await this.certNFT.connect(this.alice_0).getYearNFTID(this.alice_0.address, 2022);
    });
});


