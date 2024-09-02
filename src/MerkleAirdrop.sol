//SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title MerkeAirdrop
 * @author Sohamkumar Prajapati
 * @notice This is the contract for airdrop containg the list of the allowed address who
 *         are given permission to get the airdrops from this contract
 *         Simply this contract will provide ERC20 type tokens to allowed addresses
 */
contract MerkleAirdrop is EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    error MerkeAirdrop__Airdrop_Already_Claimed();
    error MerkeAirdrop__ProofInvalid();
    error MerkleAirdrop__InvalidSignature();

    struct Message {
        address account;
        uint256 amount;
    }

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_AirdropToken;
    mapping(address claimer => bool claimed) private claimed;
    bytes32 private constant Message_TYPEHASH = keccak256(abi.encode("Message(address account,uint256 amount)"));

    event Airdrop_Claimed(address indexed account, uint256 amount);

    constructor(bytes32 merkleRoot, address airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_AirdropToken = IERC20(airdropToken);
    }

    function claim(address account, uint256 amount, bytes32[] calldata proof, uint8 v, bytes32 r, bytes32 s) public {
        if (claimed[account]) {
            revert MerkeAirdrop__Airdrop_Already_Claimed();
        }

        if (!isValidSignature(account, getMessageDigest(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
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

    function getMessageDigest(address signer, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(Message_TYPEHASH, signer, amount)));
    }

    function isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        public
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);

        return actualSigner == signer;
    }
}
