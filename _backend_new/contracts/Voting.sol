// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    /// State Variables
    struct Candidate {
        uint id;
        string name;
        string bio;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => uint) public votedCandidate;
    address[] private votersList;
    mapping(address => bool) private voterTracked;
    uint public candidatesCount;
    address public owner;
    uint public startTime;
    uint public endTime;

    /// Events
    event votedEvent(uint indexed _candidateId);
    event candidateAdded(uint indexed _candidateId, string name, string bio);
    event candidateUpdated(uint indexed _candidateId, string name, string bio);
    event candidateDeleted(uint indexed _candidateId);
    event voteReset(address indexed voter, uint indexed candidateId);
    event voteChanged(address indexed voter, uint indexed oldCandidateId, uint indexed newCandidateId);

    /// Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier withinVotingPeriod() {
        require(block.timestamp >= startTime, "Voting has not started yet");
        require(block.timestamp <= endTime, "Voting has ended");
        _;
    }

    /// Constructor
    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + 1 days;

        _addCandidate("Michael Anderson", "A seasoned leader with 10 years of experience in decentralized governance. Committed to transparency and community-driven decision making.");
        _addCandidate("Christopher Walker", "Blockchain enthusiast and software engineer. Focuses on building scalable and secure infrastructure for Web3 applications.");
        _addCandidate("Daniel Thompson", "Advocate for privacy rights and open-source technology. Believes in empowering individuals through decentralized tools.");
        _addCandidate("James Carter", "Financial analyst turned crypto researcher. Dedicated to creating sustainable economic models for decentralized ecosystems.");
    }

    /// Internal Function
    function _addCandidate(string memory _name, string memory _bio) internal {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _bio, 0);
    }

    function _validateCandidate(uint _candidateId) internal view {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        require(bytes(candidates[_candidateId].name).length > 0, "Candidate does not exist");
    }

    function _trackVoter(address _voter) internal {
        if (!voterTracked[_voter]) {
            voterTracked[_voter] = true;
            votersList.push(_voter);
        }
    }

    function _resetVote(address _voter) internal returns (uint) {
        require(hasVoted[_voter], "Voter has not voted");

        uint previousCandidateId = votedCandidate[_voter];
        hasVoted[_voter] = false;
        votedCandidate[_voter] = 0;

        if (
            previousCandidateId > 0 &&
            previousCandidateId <= candidatesCount &&
            candidates[previousCandidateId].voteCount > 0
        ) {
            candidates[previousCandidateId].voteCount--;
        }

        emit voteReset(_voter, previousCandidateId);
        return previousCandidateId;
    }

    /// Owner Functions
    function addCandidate(string memory _name, string memory _bio) public onlyOwner {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _bio, 0);
        emit candidateAdded(candidatesCount, _name, _bio);
    }

    function setVotingPeriod(uint _startTime, uint _endTime) public onlyOwner {
        require(_endTime > _startTime, "End time must be after start time");
        startTime = _startTime;
        endTime = _endTime;
    }

    function updateCandidate(uint _candidateId, string memory _name, string memory _bio) public onlyOwner {
        _validateCandidate(_candidateId);
        candidates[_candidateId].name = _name;
        candidates[_candidateId].bio = _bio;
        emit candidateUpdated(_candidateId, _name, _bio);
    }

    function deleteCandidate(uint _candidateId) public onlyOwner {
        _validateCandidate(_candidateId);
        delete candidates[_candidateId];
        emit candidateDeleted(_candidateId);
    }

    function resetVoter(address _voter) public onlyOwner {
        require(_voter != address(0), "Invalid voter address");
        _resetVote(_voter);
    }

    function resetManyVoters(address[] calldata _voters) public onlyOwner {
        for (uint i = 0; i < _voters.length; i++) {
            if (hasVoted[_voters[i]]) {
                _resetVote(_voters[i]);
            }
        }
    }

    /// Vote Function
    function vote(uint _candidateId) public withinVotingPeriod {
        require(!hasVoted[msg.sender], "You have already voted");
        _validateCandidate(_candidateId);

        hasVoted[msg.sender] = true;
        votedCandidate[msg.sender] = _candidateId;
        _trackVoter(msg.sender);
        candidates[_candidateId].voteCount++;

        emit votedEvent(_candidateId);
    }

    function resetMyVote() public withinVotingPeriod {
        _resetVote(msg.sender);
    }

    function changeVote(uint _candidateId) public withinVotingPeriod {
        _validateCandidate(_candidateId);

        if (!hasVoted[msg.sender]) {
            vote(_candidateId);
            return;
        }

        uint previousCandidateId = votedCandidate[msg.sender];
        require(previousCandidateId != _candidateId, "Already voted for this candidate");

        if (
            previousCandidateId > 0 &&
            previousCandidateId <= candidatesCount &&
            candidates[previousCandidateId].voteCount > 0
        ) {
            candidates[previousCandidateId].voteCount--;
        }

        votedCandidate[msg.sender] = _candidateId;
        candidates[_candidateId].voteCount++;

        emit voteChanged(msg.sender, previousCandidateId, _candidateId);
        emit votedEvent(_candidateId);
    }

    function getVotersCount() public view returns (uint) {
        return votersList.length;
    }

    function getVoterAt(uint _index) public view returns (address) {
        require(_index < votersList.length, "Voter index out of bounds");
        return votersList[_index];
    }

    function getVotingStatus() public view returns (string memory) {
        if (block.timestamp < startTime) return "NOT_STARTED";
        if (block.timestamp >= startTime && block.timestamp <= endTime) return "ACTIVE";
        return "ENDED";
    }
}
