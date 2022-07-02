// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/contracts/RunChallenger.sol";

contract Admin {
    receive() external payable {}
}

contract TestRunChallenger is Test {

    RunChallenger runChallenger;
    Admin admin;
    uint constant scaledTakeRate = 0.04 * (10**18);

    function setUp() public {
        admin = new Admin();
        vm.prank(address(admin));
        runChallenger = new RunChallenger(0x3817a3dCBc02e08f88bBAF342d40B371166e6dcD);
    }

    receive() external payable {}

    // Challenge Creation
    function testAdminGetsCut(uint96 amount) public {
        vm.assume(amount > 0.001 ether);
        uint256 adminPreBalance = address(admin).balance;
        runChallenger.issueChallenge{value: amount}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
        uint256 adminPostBalance = address(admin).balance;
        assertEq(adminPreBalance + (scaledTakeRate * amount)/(10**18), adminPostBalance);
    }

    function testBountyIsTooSmall() public {
        vm.expectRevert(BountyIsTooSmall.selector);
        runChallenger.issueChallenge{value: 1000}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
    }

    function testCannotDuplicateChallengeId() public {
        runChallenger.issueChallenge{value: 1 ether}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
        vm.expectRevert();
        runChallenger.issueChallenge{value: 1 ether}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
    }

    function testChallengeAddedToMapping(uint96 amount) public {
        vm.assume(amount > 0.001 ether);
        runChallenger.issueChallenge{value: amount}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
        (address challenger, address challengee, uint bounty, uint distance, uint speed, uint issuedAt, bool complete, bool stored) = runChallenger.challengeLookup("475f0319-ce6e-4c66-a617-8894a5f1bb5e");
        assertEq(challenger, address(this));
        assertEq(challengee, 0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e);
        assertEq(bounty, amount - (scaledTakeRate * amount)/(10**18));
        assertEq(distance, 1000);
        assertEq(speed, 3);
        assertEq(issuedAt, 1656710502);
        assertTrue(!complete);
        assertTrue(stored);
    }

    function testChallengeAddedToArray() public {
        runChallenger.issueChallenge{value: 1 ether}(payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e), 1000, 3, 1656710502, "475f0319-ce6e-4c66-a617-8894a5f1bb5e");
        RunChallenger.Challenge[] memory challenges = runChallenger.getChallenges();
        assertEq(challenges.length, 1);
    }

    // Claim Bounty
    function testCannotClaimWithWrongSignature() public {
        
    }

    function testCannotUsePreviousSignature() public {
        
    }

    function testCannotClaimIfNotChallengee() public {
        
    }

    function testCannotClaimCompletedBounty() public {
        
    }

    function testChallengeeMarkedAsComplete() public {
        
    }

    function testSignatureAddedToMapping() public {
        
    }

    function testChallengeeReceivedBounty() public {
        
    }

    // Return Challenges
    function testReturnChallenges() public {
        
    }
}



//########## What do we want to test? ##########

// GET CHALLENGES
// test that we can successfully return a list of challenges


// CREATION
// Test that admin account receives ~4% of money after creation
// Test that mininum amount of money was sent
// Test that challenge was indeed added to the mapping
// Test that challenge was indeed added to the array

// CLAIM BOUNTY
// If not signer, needs to fail
// If signature already exists, needs to fail
// If message.sender is not the challengee, needs to fail
// If the challenge has already been completed, needs to fail
// If it gets past all of the above, need to verify that the challengee got the money
// Mark as challenge complete
// Signature is added to the mapping