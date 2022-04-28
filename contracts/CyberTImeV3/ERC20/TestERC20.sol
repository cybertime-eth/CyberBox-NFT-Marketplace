// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor() public ERC20("Test ERC20", "T20") {
        _mint(msg.sender, 10000000 * (10**28));
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}