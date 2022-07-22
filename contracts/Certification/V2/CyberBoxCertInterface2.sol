// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

interface CyberBoxCertInterface2 {
    event CertificationReferFeeChanged(
        uint256 referFee
    );

    event CertificationNFTReferMinted(
        address owner,
        address refer,
        uint256 tokenType,
        uint256 tokenId,
        uint256 year,
        uint256 month,
        uint256 price,
        uint256 devFee,
        uint256 referFee,
        uint256 c02
    );
}