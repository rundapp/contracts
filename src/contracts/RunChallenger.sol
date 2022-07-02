// contracts/RunChallenger.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

error BountyIsTooSmall();

contract RunChallenger is ReentrancyGuard {
    using ECDSA for bytes32;

    struct Challenge {
        address challenger;
        address payable challengee;
        uint bounty;           // Wei
        uint distance;         // Meters
        uint speed;            // Meters/Seconds
        uint issuedAt;         // Seconds since midnight, 1 Jan 1970
        bool complete;
        bool stored;
    }

    // Storage Constants
    uint public constant minimumBounty = 0.001 ether;  // Wei (0.001 ETH)
    uint public constant scaledTakeRate = 4;                // 4% of bounty amount

    // Storage Variables
    address payable public admin;
    address public signer;   
    Challenge[] private challenges; 
    mapping(bytes => bool) private signatureLookup;
    mapping(string => Challenge) public challengeLookup; 
    

    constructor(address signerAccount) {
        admin = payable(msg.sender);
        signer = signerAccount;
    }
    
    // TODO: Need to scale up distance and speed
    function issueChallenge(
        address payable _challengee, 
        uint _distance, 
        uint _speed, 
        uint _issuedAt, 
        string calldata _challengeId
    ) public payable {
        uint scaledServiceFee = scaledTakeRate * msg.value;
        uint serviceFee = scaledServiceFee / 100;

        require(challengeLookup[_challengeId].stored == false);
        
        if (msg.value < minimumBounty) {
            revert BountyIsTooSmall();
        }

        Challenge memory newChallenge = Challenge({
            challenger: msg.sender,
            challengee: _challengee,
            bounty: (msg.value - serviceFee),  // Wei
            distance: _distance,                // Meters
            speed: _speed,                      // Meters/Seconds
            issuedAt: _issuedAt,                // Seconds
            complete: false,
            stored: true
        });

        // Add challenge to mapping
        challengeLookup[_challengeId] = newChallenge;
        
        // Add challenge to array
        challenges.push(newChallenge);

        // Transfer serviceFee to admin address
        admin.transfer(serviceFee);
    }


    function claimBounty(string calldata _challengeId, bytes32 _hashedMessage, bytes calldata _signature) public nonReentrant {
        // Make sure that the signature was signed by the official signer account
        require(ECDSA.recover(_hashedMessage, _signature) == signer);

        // Make sure that the signature has not been used before
        require(signatureLookup[_signature] == false);

        // To prevent repetitive code, we can abstract challengeLookup[challengeId] into a "storage" variable of type Challenge
        Challenge storage challenge = challengeLookup[_challengeId];

        // Only the challengee of this challenge can claim the bounty
        require(msg.sender == challenge.challengee);

        // Make sure the challenge has not already been marked as complete
        require(challenge.complete == false);

        // Mark the challenge as complete
        challenge.complete = true;

        // Add signature in mapping so that it cannot be used again
        signatureLookup[_signature] = true;

        // Transfer bounty to challengee address
        challenge.challengee.transfer(challenge.bounty);
    }

    function getChallenges() public view returns (Challenge[] memory) {
        return challenges;
    }
}
