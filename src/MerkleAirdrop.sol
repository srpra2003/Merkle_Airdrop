//SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkeAirdrop
 * @author Sohamkumar Prajapati
 * @notice This is the contract for airdrop containg the list of the allowed address who
 *         are given permission to get the airdrops from this contract
 *         Simply this contract will provide ERC20 type tokens to allowed addresses
 */
contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkeAirdrop__Airdrop_Already_Claimed();
    error MerkeAirdrop__ProofInvalid();

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_AirdropToken;
    mapping(address claimer => bool claimed) private claimed;

    event Airdrop_Claimed(address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot, address airdropToken) {
        i_merkleRoot = merkleRoot;
        i_AirdropToken = IERC20(airdropToken);
    }

    function claim(address account, uint256 amount, bytes32[] memory proof) public {
        if (claimed[account]) {
            revert MerkeAirdrop__Airdrop_Already_Claimed();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        if (!MerkleProof.verify(proof, i_merkleRoot, leaf)) {
            revert MerkeAirdrop__ProofInvalid();
        }

        claimed[account] = true;
        emit Airdrop_Claimed(account, amount);

        i_AirdropToken.safeTransfer(account, amount);
    }

    function getMerkleRoot() public view returns (bytes32) {
        return i_merkleRoot;
    }
}
