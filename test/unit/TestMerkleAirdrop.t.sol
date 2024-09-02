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
    uint256 private AMOUNT_TO_CLAIM = 25 ether;

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
        (address notValidPerson, uint256 inValidPersonPrivateKey) = makeAddrAndKey("InvalidPerson");
        bytes32 digest = merkleAirdrop.getMessageDigest(notValidPerson, AMOUNT_TO_CLAIM);
        (uint8 _v, bytes32 _r, bytes32 _s) = signMessage(inValidPersonPrivateKey,digest);

        proof = vm.readFile(string.concat(vm.projectRoot(), "/script/target/output.json")).readBytes32Array("[0].proof");

        for (uint256 i = 0; i < 2; i++) {
            console.logBytes32(proof[i]);
        }

        vm.startPrank(USER);
        vm.expectRevert(MerkleAirdrop.MerkeAirdrop__ProofInvalid.selector);
        merkleAirdrop.claim(notValidPerson, 25e18, proof, _v, _r, _s);
    }

    function testValidUserCanCollectAirdrop() public {
        
        address allowedUser = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readAddress("[0].inputs[0]");
        uint256 allowedUserPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        uint256 allowedUserInitialTokenBalance = launchToken.balanceOf(allowedUser);

        proof = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readBytes32Array("[0].proof");

        bytes32 digest = merkleAirdrop.getMessageDigest(allowedUser,AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(allowedUserPrivateKey,digest);

        vm.startPrank(USER);
        merkleAirdrop.claim(allowedUser,AMOUNT_TO_CLAIM,proof,v,r,s);
        vm.stopPrank();

        uint256 allowedUserFinalTokenBalance = launchToken.balanceOf(allowedUser);
        assertEq(allowedUserInitialTokenBalance + AMOUNT_TO_CLAIM , allowedUserFinalTokenBalance);
    }

    function testAirdropscanOnlyBeClaimedOnce() public {
        address allowedUser = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readAddress("[0].inputs[0]");
        uint256 allowedUserPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");

        proof = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readBytes32Array("[0].proof");

        bytes32 digest = merkleAirdrop.getMessageDigest(allowedUser,AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(allowedUserPrivateKey,digest);

        vm.startPrank(USER);
        merkleAirdrop.claim(allowedUser,AMOUNT_TO_CLAIM,proof,v,r,s);
        vm.stopPrank();

        vm.expectRevert(MerkleAirdrop.MerkeAirdrop__Airdrop_Already_Claimed.selector);
        merkleAirdrop.claim(allowedUser,AMOUNT_TO_CLAIM,proof,v,r,s);
    }

    function testClaimFunctionrevertsWhenPassingWrongSignature() public {
        address allowedUser = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readAddress("[0].inputs[0]");
        // uint256 allowedUserPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY"); 
        (,uint256 fakePrivateKey) = makeAddrAndKey("Fake Person");

        proof = vm.readFile(string.concat(vm.projectRoot(),"/script/target/output.json")).readBytes32Array("[0].proof");

        bytes32 digest = merkleAirdrop.getMessageDigest(allowedUser,AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(fakePrivateKey,digest);

        vm.startPrank(USER);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        merkleAirdrop.claim(allowedUser,AMOUNT_TO_CLAIM,proof,v,r,s);
        vm.stopPrank();
    }

    function signMessage(uint256 privateKey, bytes32 digest) public pure returns(uint8 v, bytes32 r, bytes32 s) {
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(privateKey, digest);
        return (_v, _r, _s);
    }
}
