// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {FundMe} from "../src/Fundme.sol";

/// @notice Fund the most recently deployed FundMe contract.
contract FundFundMe is Script {
    uint256 public constant SEND_VALUE = 0.1 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s wei", SEND_VALUE);
    }

    function run() external {
        // Export FUNDME_ADDRESS=<deployed address> before running this script.
        address mostRecentlyDeployed = vm.envAddress("FUNDME_ADDRESS");
        fundFundMe(mostRecentlyDeployed);
    }
}

/// @notice Withdraw from the most recently deployed FundMe contract (owner only).
contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        // Export FUNDME_ADDRESS=<deployed address> before running this script.
        address mostRecentlyDeployed = vm.envAddress("FUNDME_ADDRESS");
        withdrawFundMe(mostRecentlyDeployed);
    }
}
