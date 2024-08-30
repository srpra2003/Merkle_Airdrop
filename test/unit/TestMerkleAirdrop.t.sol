//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployMerkleAirdrop} from "../../script/DeployMerkleAirdrop.s.sol";
import {MerkleAirdrop} from "../../src/MerkleAirdrop.sol";
import {LaunchToken} from "../../src/LaunchToken.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract TestMerkleAirdrop is Test {
    using stdJson for string;

    DeployMerkleAirdrop private deployMerkleAirdrop;
    MerkleAirdrop private merkleAirdrop;
    LaunchToken private launchToken;
    bytes32 private merkleRoot;
    bytes32[] private proof;

    address private USER = makeAddr("user");
    uint256 private INITIAL_BALANCE = 100 ether;

    event Airdrop_Claimed(address indexed account, uint256 amount);

    function setUp() public {
        deployMerkleAirdrop = new DeployMerkleAirdrop();
        (merkleAirdrop, launchToken, merkleRoot) = deployMerkleAirdrop.run();

        vm.deal(USER, INITIAL_BALANCE);
    }

    function testMerkleAirdropisOwnerOfLaunchTokenContract() public view {
        address launchTokenContractOwner = launchToken.owner();

        assertEq(launchTokenContractOwner, address(merkleAirdrop));
    }

    function testInvalidAccountCannotCollectAirdrop() public {
        address notValidPerson = makeAddr("invalidPerson");

        proof = vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readBytes32Array("[0].proof");

        for (uint256 i = 0; i < 2; i++) {
            console.logBytes32(proof[i]);
        }

        vm.startPrank(USER);
        vm.expectRevert(MerkleAirdrop.MerkeAirdrop__ProofInvalid.selector);
        merkleAirdrop.claim(notValidPerson, 25e18, proof);
    }

    function testValidUserCanCollectAirdrop() public {
        address validUser =
            vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readAddress("[0].inputs[0]");
        proof = vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readBytes32Array("[0].proof");
        console.log(validUser);

        vm.startPrank(USER);
        vm.expectEmit(true, false, false, true, address(merkleAirdrop));
        emit Airdrop_Claimed(validUser, 25e18);
        merkleAirdrop.claim(validUser, 25e18, proof);
    }

    function testAirdropscanOnlyBeClaimedOnce() public {
        address validUser =
            vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readAddress("[0].inputs[0]");
        proof = vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readBytes32Array("[0].proof");
        console.log(validUser);

        vm.startPrank(USER);
        merkleAirdrop.claim(validUser, 25e18, proof);

        vm.expectRevert(MerkleAirdrop.MerkeAirdrop__Airdrop_Already_Claimed.selector);
        merkleAirdrop.claim(validUser, 25e18, proof);
    }
}
