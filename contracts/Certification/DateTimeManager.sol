// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract DateTimeManager {

    mapping (uint256 => uint256) public YEARS; /// year num => year start timestamp
    mapping (uint256 => uint256) public MONTHS; /// year num * 100 + month num => month start timestamp

    uint256 public current_year;
    uint256 public current_month;

    constructor() public {
        YEARS[2022] = 1641020400; /// timestamp of 2022-01-01
        YEARS[2023] = 1672556400; /// timestamp of 2023-01-01
        YEARS[2024] = 1704092400; /// timestamp of 2024-01-01

        MONTHS[202203] = 1646118000; /// timestamp of 2022-03-01
        MONTHS[202303] = 1677654000; /// timestamp of 2023-03-01
        MONTHS[202403] = 1709276400; /// timestamp of 2024-03-01

        current_year = 2022;
        current_month = 5;

        generateMonthStartTimes(current_year);
        determineDateTime();
    }

    function generateMonthStartTimes(uint256 year) private {
        MONTHS[year * 100 + 1] = YEARS[year];
        MONTHS[year * 100 + 2] = YEARS[year] + (24*3600*31);
        MONTHS[year * 100 + 4] = MONTHS[year * 100 + 3] + (24*3600*31);
        MONTHS[year * 100 + 5] = MONTHS[year * 100 + 4] + (24*3600*30);
        MONTHS[year * 100 + 6] = MONTHS[year * 100 + 5] + (24*3600*31);
        MONTHS[year * 100 + 7] = MONTHS[year * 100 + 6] + (24*3600*30);
        MONTHS[year * 100 + 8] = MONTHS[year * 100 + 7] + (24*3600*31);
        MONTHS[year * 100 + 9] = MONTHS[year * 100 + 8] + (24*3600*31);
        MONTHS[year * 100 + 10] = MONTHS[year * 100 + 9] + (24*3600*30);
        MONTHS[year * 100 + 11] = MONTHS[year * 100 + 10] + (24*3600*31);
        MONTHS[year * 100 + 12] = MONTHS[year * 100 + 11] + (24*3600*30);
    }

    function determineDateTime() public {
        uint256 current_time = block.timestamp;
        uint256 nextYearStartTime = YEARS[current_year + 1];
        if(current_time > nextYearStartTime) {
            current_year = current_year + 1;
            generateMonthStartTimes(current_year);
        }

        uint256 current_month_start = MONTHS[current_year * 100 + current_month];
        uint256 next_month_start = MONTHS[current_year * 100 + current_month + 1];
        if(current_time > next_month_start || current_time < current_month_start){
            for(uint256 i = 1; i <= 12; i ++){
                uint256 select_month_start = MONTHS[current_year * 100 + i];
                if(current_time < select_month_start){
                    break;
                }
                current_month = i;
            }
        }
    }

    function getDateTimeSymbol() public returns (uint256 year, uint256 month){
        determineDateTime();
        return (current_year, current_month);
    }


    function addNewYear(uint256 year, uint256 startTimeStamp) public {
        YEARS[year] = startTimeStamp;
    }
    function addNewMarch(uint256 year, uint256 startTimeStamp) public {
        uint256 march_key = year * 100 + 3;
        MONTHS[march_key] = startTimeStamp;
    }
    function setCurrentYear(uint256 year) public {
        current_year = year;
    }
    function setCurrentMonth(uint256 month) public {
        current_month = month;
    }
}