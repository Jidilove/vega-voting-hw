// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VegaVoting} from "../src/VegaVotingSystem.sol";

contract Deploy is Script {
    function run() external returns (VegaVoting deployed) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(privateKey);
        deployed = new VegaVoting(vm.addr(privateKey));
        vm.stopBroadcast();
    }
}
