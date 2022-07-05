// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/contracts/RunChallenger.sol";

contract Admin {
    receive() external payable {}
}

contract TestIssueChallenge is Test {

    // Contracts
    RunChallenger runChallenger;
    Admin admin;

    // Common Testing Variables
    uint constant scaledTakeRate = 0.04 * (10**18);

    // Challenge Issuance Variables
    address payable testChallengee = payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e);
    uint testDistance = 1000;
    uint testPace = 3;
    uint testIssuedAt = 1656710502;
    string constant testChallengeId = "475f0319-ce6e-4c66-a617-8894a5f1bb5e";

    // Claim Bounty Variables
    address testSigner = 0x9E81eC9222C4F5F4B5f5C442033C94111C281657;
    
    function setUp() public {
        admin = new Admin();
        vm.prank(address(admin));
        runChallenger = new RunChallenger(testSigner);
    }

    receive() external payable {}

    function testAdminGetsCut(uint96 amount) public {
        vm.assume(amount > 0.001 ether);
        uint256 adminPreBalance = address(admin).balance;
        runChallenger.issueChallenge{value: amount}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
        uint256 adminPostBalance = address(admin).balance;
        assertEq(adminPreBalance + (scaledTakeRate * amount)/(10**18), adminPostBalance);
    }

    function testBountyIsTooSmall() public {
        vm.expectRevert("Bounty is too small.");
        runChallenger.issueChallenge{value: 1000}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
    }

    function testCannotDuplicateChallengeId() public {
        runChallenger.issueChallenge{value: 1 ether}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
        vm.expectRevert("_challengeId is invalid.");
        runChallenger.issueChallenge{value: 1 ether}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
    }

    function testCannotHaveZeroAddressChallengee() public {
        vm.expectRevert("_challengee is invalid.");
        runChallenger.issueChallenge{value: 1 ether}(payable(0), testDistance, testPace, testIssuedAt, testChallengeId);
    }

    function testChallengeAddedToMapping(uint96 amount) public {
        vm.assume(amount > 0.001 ether);
        runChallenger.issueChallenge{value: amount}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
        (address challenger, address challengee, uint bounty, uint distance, uint speed, uint issuedAt, bool complete) = runChallenger.challengeLookup(testChallengeId);
        assertEq(challenger, address(this));
        assertEq(challengee, testChallengee);
        assertEq(bounty, amount - (scaledTakeRate * amount)/(10**18));
        assertEq(distance, testDistance);
        assertEq(speed, testPace);
        assertEq(issuedAt, testIssuedAt);
        assertTrue(!complete);
    }

    function testChallengeAddedToArray() public {
        runChallenger.issueChallenge{value: 1 ether}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
        RunChallenger.Challenge[] memory challenges = runChallenger.getChallenges();
        assertEq(challenges.length, 1);
    }
}

contract TestClaimBounty is Test {

    // Contracts
    RunChallenger runChallenger;
    Admin admin;

    // Common Testing Variables
    uint constant scaledTakeRate = 0.04 * (10**18);

    // Challenge Issuance Variables
    address payable testChallengee = payable(0xdF197C452b63227ACfEbAb8dcCf58E6E5f8AD02e);
    uint testDistance = 1000;
    uint testPace = 3;
    uint testIssuedAt = 1656710502;
    string constant testChallengeId = "475f0319-ce6e-4c66-a617-8894a5f1bb5e";
    string constant testChallengeId2 = "eb6fb282-2339-413b-bbba-832ff65a796f";

    // Claim Bounty Variables
    address testSigner = 0x9E81eC9222C4F5F4B5f5C442033C94111C281657;
    bytes32 testHashedMessage = 0xdbabd60809b0384ae86dad6f0c464d0a9eb98133f9a36cfa6d56ad5bd089d167;
    bytes testValidSignature = hex"bd81f3c460c0e6859d75ce680f810b2a3d902136b40c1403429f656c92884ec35a26c3b7d591227032da6120ff7befa22a577d0cc2614322605680931cc892a11b";
    bytes testInvalidSignature = hex"e136791cd6940c0c099288564b9ecece9cbc3d534bfddb096ef3561bf0ebcc705fc52809608de2adf955986a175721679a864fea957e3c800559d6ec6cef18bb1b";

    function setUp() public {
        admin = new Admin();
        vm.prank(address(admin));
        runChallenger = new RunChallenger(testSigner);
        runChallenger.issueChallenge{value: 1 ether}(testChallengee, testDistance, testPace, testIssuedAt, testChallengeId);
    }

    function testCannotClaimWithWrongSignature() public {
        vm.prank(testChallengee);
        vm.expectRevert("Signer not authorized."); // Maybe throw actual error here?
        runChallenger.claimBounty(testChallengeId, testHashedMessage, testInvalidSignature);
    }

    function testCannotUsePreviousSignature() public {
        vm.prank(testChallengee);
        runChallenger.claimBounty(testChallengeId, testHashedMessage, testValidSignature);
        vm.prank(testChallengee);
        vm.expectRevert("Signature was used before.");
        runChallenger.claimBounty("", testHashedMessage, testValidSignature);
    }

    function testCannotClaimIfNotChallengee() public { 
        vm.expectRevert("Sender not authorized.");
        runChallenger.claimBounty(testChallengeId, testHashedMessage, testValidSignature);
    }

    function testCannotClaimCompletedBounty() public {
        bytes32 testSecondHashedMessage = 0xfa847768b4cf238e543350dd5878971ad1485e06b2945f825ca7f83f2b0bea2a;
        bytes memory testSecondValidSignature = hex"cbd316645395e1d6e8c115c19548906ccb7aac1d8c07a62f22084fa3c4c29178538d1ee2ffa8a3f2841377ed7db5b03f51fb82cf97e59b20906d9bb449e94bc51c";

        vm.prank(testChallengee);
        runChallenger.claimBounty(testChallengeId, testHashedMessage, testValidSignature);
        vm.prank(testChallengee);
        vm.expectRevert("Challenge already complete.");
        runChallenger.claimBounty(testChallengeId, testSecondHashedMessage, testSecondValidSignature);
    }

    function testChallengeeMarkedAsComplete() public {
        vm.prank(testChallengee);
        runChallenger.claimBounty(testChallengeId, testHashedMessage, testValidSignature);
        ( , , , , , , bool complete) = runChallenger.challengeLookup(testChallengeId);
        assertTrue(complete);
    }

    function testChallengeeReceivedBounty() public {
        // 1. Create challenge (with admin as the challengee)
        runChallenger.issueChallenge{value: 1 ether}(payable(admin), testDistance, testPace, testIssuedAt, testChallengeId2);
        // 2. Claim Bounty
        uint256 adminPreBalance = address(admin).balance;
        vm.prank(address(admin));
        runChallenger.claimBounty(testChallengeId2, testHashedMessage, testValidSignature);
        uint256 adminPostBalance = address(admin).balance;
        assertEq(adminPreBalance + (1 ether - (scaledTakeRate * 1 ether)/(10**18)), adminPostBalance);
    }
}