// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CodingHackathonRewards {
    struct Participant {
        uint points;
        uint rewardsClaimed;
    }

    struct Hackathon {
        string title;
        uint rewardPool;
        uint startTime;
        uint endTime;
        bool isActive;
    }

    address public owner;
    uint public totalHackathons;
    mapping(uint => Hackathon) public hackathons;
    mapping(uint => mapping(address => Participant)) public participants;

    event HackathonCreated(uint indexed hackathonId, string title, uint rewardPool, uint startTime, uint endTime);
    event PointsUpdated(uint indexed hackathonId, address indexed participant, uint points);
    event RewardsClaimed(uint indexed hackathonId, address indexed participant, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hackathonExists(uint hackathonId) {
        require(hackathons[hackathonId].startTime > 0, "Hackathon does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createHackathon(string memory title, uint rewardPool, uint startTime, uint endTime) external onlyOwner {
        require(endTime > startTime, "End time must be after start time");
        require(rewardPool > 0, "Reward pool must be greater than zero");

        hackathons[totalHackathons] = Hackathon({
            title: title,
            rewardPool: rewardPool,
            startTime: startTime,
            endTime: endTime,
            isActive: true
        });

        emit HackathonCreated(totalHackathons, title, rewardPool, startTime, endTime);
        totalHackathons++;
    }

    function updatePoints(uint hackathonId, address participant, uint points) external onlyOwner hackathonExists(hackathonId) {
        Hackathon storage hackathon = hackathons[hackathonId];
        require(block.timestamp >= hackathon.startTime && block.timestamp <= hackathon.endTime, "Hackathon is not active");

        participants[hackathonId][participant].points += points;

        emit PointsUpdated(hackathonId, participant, participants[hackathonId][participant].points);
    }

    function claimRewards(uint hackathonId) external hackathonExists(hackathonId) {
        Hackathon storage hackathon = hackathons[hackathonId];
        require(block.timestamp > hackathon.endTime, "Hackathon is still active");

        Participant storage participant = participants[hackathonId][msg.sender];
        require(participant.points > 0, "No points earned");
        require(participant.rewardsClaimed == 0, "Rewards already claimed");

        uint totalPoints = 0;
        for (uint i = 0; i < totalHackathons; i++) {
            totalPoints += participants[i][msg.sender].points;
        }

        uint reward = (participant.points * hackathon.rewardPool) / totalPoints;
        participant.rewardsClaimed = reward;

        payable(msg.sender).transfer(reward);

        emit RewardsClaimed(hackathonId, msg.sender, reward);
    }

    function deactivateHackathon(uint hackathonId) external onlyOwner hackathonExists(hackathonId) {
        hackathons[hackathonId].isActive = false;
    }

    receive() external payable {}
}
