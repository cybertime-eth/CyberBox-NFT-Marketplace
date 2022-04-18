// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CCOCommittee {
    using SafeMath for uint256;

    event OlympicTitleChanged(
        uint256 olympicNumber,
        string olympicTitle,
        string olympicDescription
    );
    event OlympicMarkChanged(
        uint256 olympicNumber,
        string olympicMark
    );
    event OlympicMedalChanged(
        uint256 olympicNumber,
        string goldMedal,
        string silverMedal,
        string bronzeMedal
    );
    event OlympicSemiMatched(
        uint256 olympicNumber,
        address athlete0,
        address athlete1
    );
    event OlympicStarted(
        uint256 olympicNumber,
        uint256 startDate,
        uint256 periodDays
    );

    address public dev; // developer address

    uint256 public _olympicNumber = 1; // 1th CCO
    string public _olympicTitle; // Main title of 1th CCO
    string public _olympicDescription; // Main description of 1th CCO
    string public _olympicMark; // Main mark of 1th CCO
    uint256 public _seasonStartTime; // 1th olympic start time
    uint256 public _seasonLength; // 1th olympic total day

    string public _goldMedal; // Gold medal image
    string public _silverMedal; // Silver medal image
    string public _bronzeMedal; // Bronze medal image

    address[] public athletes;
    mapping(address => address) semiMatching;

    modifier onlyDev() {
        require(msg.sender == dev, "auction: wrong developer");
        _;
    }

    constructor(
        address _dev
        ) public {
        dev = _dev;

        _olympicNumber = 1;
        _olympicTitle = "1TH CELO CYBER OLYMPIC GAME";
        _olympicDescription = "First olympic game on cyber world.";
        _olympicMark = "https://cybertime.mypinata.cloud/ipfs/QmW91V2Dum899CAZ8MzqUEP7tJ5kSXGmqD2LLc8TksDrTP/mark/mark.jpg";
        _goldMedal = "https://cybertime.mypinata.cloud/ipfs/QmW91V2Dum899CAZ8MzqUEP7tJ5kSXGmqD2LLc8TksDrTP/medal/1.jpg";
        _silverMedal = "https://cybertime.mypinata.cloud/ipfs/QmW91V2Dum899CAZ8MzqUEP7tJ5kSXGmqD2LLc8TksDrTP/medal/2.jpg";
        _bronzeMedal = "https://cybertime.mypinata.cloud/ipfs/QmW91V2Dum899CAZ8MzqUEP7tJ5kSXGmqD2LLc8TksDrTP/medal/3.jpg";
    
        emit OlympicTitleChanged(_olympicNumber, _olympicTitle, _olympicDescription);
        emit OlympicMarkChanged(_olympicNumber, _olympicMark);
        emit OlympicMedalChanged(_olympicNumber, _goldMedal, _silverMedal, _bronzeMedal);
    }

    function enterOlympicTitle(
        string memory olympicTitle,
        string memory olympicDescription
    ) external onlyDev {
        _olympicTitle = olympicTitle;
        _olympicDescription = olympicDescription;
        emit OlympicTitleChanged(_olympicNumber, _olympicTitle, _olympicDescription);
    }

    function enterOlympicMark(
        string memory olympicMark
    ) external onlyDev {
        _olympicMark = olympicMark;
        emit OlympicMarkChanged(_olympicNumber, _olympicMark);
    }

    function enterOlympicMedal(
        string memory goldMedal,
        string memory silverMedal,
        string memory bronzeMedal
    ) external onlyDev {
        _goldMedal = goldMedal;
        _silverMedal = silverMedal;
        _bronzeMedal = bronzeMedal;
        emit OlympicMedalChanged(_olympicNumber, _goldMedal, _silverMedal, _bronzeMedal);
    }

    function enterSemiMatching(
        address athletes_0,
        address athletes_1
    ) external onlyDev {
        athletes.push(athletes_0);
        athletes.push(athletes_1);
        semiMatching[athletes_0] = athletes_1;
        semiMatching[athletes_1] = athletes_0;
        emit OlympicSemiMatched(_olympicNumber, athletes_0, athletes_1);
    }
    function getSemiMatching(
        address athlete
    ) public view returns (address) {
        return semiMatching[athlete];
    }

    function startOlympic(
        uint256 startOlympic,
        uint256 periodDays
    ) external onlyDev {
        _seasonStartTime = startOlympic;
        _seasonLength = periodDays;
        emit OlympicStarted(_olympicNumber, _seasonStartTime, _seasonLength);
    }
}