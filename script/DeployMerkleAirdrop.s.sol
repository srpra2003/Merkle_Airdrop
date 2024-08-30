//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {LaunchToken} from "../src/LaunchToken.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract DeployMerkleAirdrop is Script {
    using stdJson for string;

    string OUTPUT_JSON_PATH = "/script/target/output.json";
    string INPUT_JSON_PATH = "/script/target/input.json";

    string elementsOutput = vm.readFile(string.concat(vm.projectRoot(), OUTPUT_JSON_PATH));
    string elemetsInput = vm.readFile(string.concat(vm.projectRoot(), INPUT_JSON_PATH));
    bytes32 merkleRoot = elementsOutput.readBytes32("[0].root");
    uint256 claimers = elemetsInput.readUint(".count");

    function deployAirdropProject() public returns (MerkleAirdrop, LaunchToken, bytes32) {
        vm.startBroadcast();
        LaunchToken airdropToken = new LaunchToken();
        MerkleAirdrop airdropEngine = new MerkleAirdrop(merkleRoot, address(airdropToken));
        airdropToken.mint(address(airdropEngine), claimers * 25e18);
        airdropToken.transferOwnership(address(airdropEngine));
        vm.stopBroadcast();

        return (airdropEngine, airdropToken, merkleRoot);
    }

    function howToParseJsonFile() public view {
        console.log(elementsOutput.readString("[0].root")); // as in json file hirarcy contains first array of objects so specifying in parent to child manner
        console.log("The first Address inside the first object", elementsOutput.readStringArray("[0].inputs")[0]);
        console.log("The amount that address is allowed to airdop", elementsOutput.readStringArray("[0].inputs")[1]);
        console.logBytes32(elementsOutput.readBytes32("[0].root")); // to include bytes32
    }

    function run() external returns (MerkleAirdrop, LaunchToken, bytes32) {
        howToParseJsonFile();

        return deployAirdropProject();
    }
}
