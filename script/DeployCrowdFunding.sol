// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { CrowdFunding } from "src/CrowdFunding.sol";

contract DeployCrowdFunding is Script {
    address ownerAddress = 0xA6Bb40e9F5952284FA6105aa3bB9956E1A739D98;

    function run() public returns(CrowdFunding crowdFunding) {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerKey);
        crowdFunding = new CrowdFunding(ownerAddress);
        vm.stopBroadcast();
    }
}