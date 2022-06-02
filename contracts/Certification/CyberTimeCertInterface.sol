// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

interface CyberTimeCertInterface {
    event CertificationNFTMinted(
        address owner,
        uint256 tokenType,
        uint256 tokenId,
        uint256 year,
        uint256 month,
        uint256 price,
        uint256 c02
    );

    event CertificationNFTBurned(
        address owner,
        uint256 tokenType,
        uint256 tokenId,
        uint256 year,
        uint256 month
    );

    event CertificationNFTExchanged(
        address owner,
        uint256 fromType,
        uint256 toType,
        uint256 year
    );

    event CertificationTokenListed(
        address nftAddress,
        uint256 indexed tokenId, 
        address indexed fromAddress, 
        uint256 minValue
    );
    event CertificationTokenDelisted(
        address nftAddress,
        uint256 indexed tokenId
    );
    event CertificationCleanList(
        address nftAddress,
        uint256 tokenId
    );

    event CertificationPayment(
        address fromAddress,
        address toAddress,
        uint256 tokenId,
        address nftAddress,
        uint256 paymentType,
        uint256 amount
    );
    event CertificationTokenBought(
        address nftAddress,
        uint256 tokenId,
        address fromAddress, 
        address toAddress,
        uint256 total,
        uint256 value,
        uint256 fees
    );
    event CertificationTokenTransfered(
        address nftAddress,
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 total
    );
    event CertificationTokenPriceChanged(
        address nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
}