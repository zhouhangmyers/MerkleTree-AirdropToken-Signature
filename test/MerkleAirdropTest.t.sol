//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    BagelToken public bagelToken;
    MerkleAirdrop public merkleAirdrop;
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public constant AMOUNT_TO_SENDE = 50 * 1e18;
    bytes32[] public PROOF;
    address public USER;
    uint256 public privateKey;
    address public GASPAYER;

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployMerkleAirdrop = new DeployMerkleAirdrop();
            (merkleAirdrop, bagelToken) = deployMerkleAirdrop.run();
        } else {
            bagelToken = new BagelToken();
            merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, bagelToken);
            bagelToken.mint(bagelToken.owner(), AMOUNT_TO_SENDE);
            // console.log(address(this));
            // console.log(bagelToken.owner());
            bagelToken.transfer(address(merkleAirdrop), AMOUNT_TO_SENDE);
        }
        (USER, privateKey) = makeAddrAndKey("user");
        GASPAYER = makeAddr("gaspayer");
        PROOF = [
            bytes32(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a),
            bytes32(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576)
        ];
    }

    function testUserCanClaim() external {
        // console.log(msg.sender);
        uint256 balance = bagelToken.balanceOf(USER);
        console.log("Balance: %d", balance);
        bytes32 digest = merkleAirdrop.getMessageHash(USER, AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        vm.prank(GASPAYER);
        merkleAirdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 newBalance = bagelToken.balanceOf(USER);
        console.log("New Balance: %d", newBalance);

        assertEq(newBalance, AMOUNT_TO_CLAIM);
    }
}
