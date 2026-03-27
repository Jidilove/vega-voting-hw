// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VegaVoting, VVToken} from "../src/VegaVotingSystem.sol";

contract VegaVotingTest is Test {
    VegaVoting voting;
    VVToken token;

    address owner = address(1);
    address alice = address(2);
    address bob = address(3);

    function setUp() public {
        vm.prank(owner);
        voting = new VegaVoting(owner);

        token = voting.vvToken();

        vm.prank(owner);
        voting.faucetMint(alice, 1000 ether);

        vm.prank(owner);
        voting.faucetMint(bob, 1000 ether);

        vm.prank(alice);
        token.approve(address(voting), type(uint256).max);

        vm.prank(bob);
        token.approve(address(voting), type(uint256).max);
    }

    function testStakeAndVote() public {
        vm.prank(alice);
        voting.stake(100 ether, 4);

        vm.prank(bob);
        voting.stake(50 ether, 2);

        bytes32 id = keccak256("vote-1");

        vm.prank(owner);
        voting.createVoting(
            id,
            block.timestamp + 3 days,
            1,
            "Should proposal 1 pass?"
        );

        vm.prank(alice);
        voting.vote(id, true);

        vm.prank(bob);
        voting.vote(id, false);

        (
            bytes32 voteId,
            uint256 deadline,
            uint256 threshold,
            string memory description,
            uint256 yesVotes,
            uint256 noVotes,
            bool finalized,
            bool passed,
            uint256 nftId
        ) = voting.getVoting(id);

        assertEq(voteId, id);
        assertGt(deadline, block.timestamp);
        assertEq(threshold, 1);
        assertEq(description, "Should proposal 1 pass?");
        assertGt(yesVotes, 0);
        assertGt(noVotes, 0);
        assertFalse(finalized);
        assertFalse(passed);
        assertEq(nftId, 0);
    }

    function testFinalizeAfterDeadline() public {
        vm.prank(alice);
        voting.stake(100 ether, 4);

        bytes32 id = keccak256("vote-2");

        vm.prank(owner);
        voting.createVoting(
            id,
            block.timestamp + 1 days,
            type(uint256).max,
            "Finalize by deadline"
        );

        vm.prank(alice);
        voting.vote(id, true);

        vm.warp(block.timestamp + 2 days);

        voting.finalize(id);

        (
            ,
            ,
            ,
            ,
            uint256 yesVotes,
            ,
            bool finalized,
            bool passed,
            uint256 nftId
        ) = voting.getVoting(id);

        assertTrue(finalized);
        assertGt(yesVotes, 0);
        assertFalse(passed);
        assertGt(nftId, 0);
    }

    function testEarlyFinalizeWhenThresholdReached() public {
        vm.prank(alice);
        voting.stake(100 ether, 4);

        bytes32 id = keccak256("vote-3");

        vm.prank(owner);
        voting.createVoting(
            id,
            block.timestamp + 10 days,
            1,
            "Early finalize test"
        );

        vm.prank(alice);
        voting.vote(id, true);

        (
            ,
            ,
            ,
            ,
            uint256 yesVotes,
            ,
            bool finalized,
            bool passed,
            uint256 nftId
        ) = voting.getVoting(id);

        assertGt(yesVotes, 0);
        assertTrue(finalized);
        assertTrue(passed);
        assertGt(nftId, 0);
    }
}
