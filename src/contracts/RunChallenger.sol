// contracts/RunChallenger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract RunChallenger is ReentrancyGuard {
    using ECDSA for bytes32;

    struct Challenge {
        string challengeId;
        address challenger;
        address payable challengee;
        uint bounty;           // Wei
        uint distance;         // Centimeters
        uint speed;            // Centimeters/Second
        uint issuedAt;         // Seconds since midnight, 1 Jan 1970
        bool complete;
    }

    // Storage Constants
    uint public constant minimumBounty = 4 ether;      // 4 MATIC (~$2.50)
    uint public constant maximumSpeed = 1200;          // Centimeters/Second
    uint public constant scaledTakeRate = 4;           // 4% of bounty
    uint public constant minimumDistance = 40000;      // Centimeters

    // Storage Variables
    address payable public admin;
    address public signer;   
    Challenge[] private challenges; 
    mapping(bytes => bool) private signatureLookup;
    mapping(string => uint) public challengesArrayIndexLookup;
    mapping(string => Challenge) public challengeLookup;
    
    constructor(address signerAccount) {
        admin = payable(msg.sender);
        signer = signerAccount;
    }
    
    function issueChallenge(
        address payable _challengee, 
        uint _distance, 
        uint _speed, 
        uint _issuedAt,
        string calldata _challengeId
    ) public payable {
        // Challengee cannot have an empty address
        require(_challengee != address(0), "_challengee is invalid.");

        // Cannot update existing challenge
        require(challengeLookup[_challengeId].challengee == address(0), "_challengeId is invalid.");
        
        // Must send at least the minimum bounty value
        require(msg.value >= minimumBounty, "Bounty is too small.");

        // Must send a distance greater than minimum distance
        require(_distance >= minimumDistance, "Distance is too small.");

        // Must send a speed less than maxiumum speed
        require(_speed <= maximumSpeed, "Speed is too fast.");

        uint serviceFee = (scaledTakeRate * msg.value) / 100;

        Challenge memory newChallenge = Challenge({
            challengeId: _challengeId,
            challenger: msg.sender,
            challengee: _challengee,
            bounty: (msg.value - serviceFee),   // Wei
            distance: _distance,                // Meters
            speed: _speed,                      // Meters/Seconds
            issuedAt: _issuedAt,                // Seconds
            complete: false
        });

        // Add challenge to mapping
        challengeLookup[_challengeId] = newChallenge;
          
        // Add challenge to array
        challenges.push(newChallenge);

        // Add index this challenge is stored at in challenges array
        challengesArrayIndexLookup[_challengeId] = challenges.length - 1;

        // Transfer serviceFee to admin address
        admin.transfer(serviceFee);
    }


    function claimBounty(string calldata _challengeId, bytes32 _hashedMessage, bytes calldata _signature) public nonReentrant {
        // Make sure that the signature was signed by the official signer account
        require(ECDSA.recover(_hashedMessage, _signature) == signer, "Signer not authorized.");

        // Make sure that the signature has not been used before
        require(signatureLookup[_signature] == false, "Signature was used before.");

        // Lookup challenge and store as a "storage" variable, as it will be updated
        Challenge storage challenge = challengeLookup[_challengeId];

        // Only the challengee of this challenge can claim the bounty
        require(msg.sender == challenge.challengee, "Sender not authorized.");

        // Make sure the challenge has not already been marked as complete
        require(challenge.complete == false, "Challenge already complete.");

        // Mark the challenge as complete in mapping
        challenge.complete = true;

        // Mark the challenge as complete in array
        Challenge storage challengeInArray = challenges[challengesArrayIndexLookup[_challengeId]];
        challengeInArray.complete = true;

        // Add signature in mapping so that it cannot be used again
        signatureLookup[_signature] = true;

        // Transfer bounty to challengee address
        challenge.challengee.transfer(challenge.bounty);
    }

    function getChallenges() public view returns (Challenge[] memory) {
        return challenges;
    }
}
