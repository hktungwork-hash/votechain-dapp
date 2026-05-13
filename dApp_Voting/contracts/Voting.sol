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
    address[] private voters;
    mapping(address => bool) private knownVoter;
    uint public candidatesCount;
    address public owner;
    uint public startTime;
    uint public endTime;

    /// Events
    event votedEvent(address indexed voter, uint indexed candidateId);
    event candidateAdded(uint indexed _candidateId, string name, string bio);
    event candidateUpdated(uint indexed _candidateId, string name, string bio);
    event candidateDeleted(uint indexed _candidateId);
    event voteReset(address indexed voter, uint indexed candidateId);

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

        _addCandidate(
            unicode"Nguyễn Văn An",
            unicode"Ứng viên ưu tiên minh bạch trong quản trị, cải thiện trải nghiệm cử tri và công khai toàn bộ tiến trình bầu cử."
        );

        _addCandidate(
            unicode"Trần Minh Khoa",
            unicode"Kỹ sư công nghệ tập trung vào hạ tầng blockchain an toàn, ổn định và dễ kiểm chứng cho cộng đồng."
        );

        _addCandidate(
            unicode"Lê Quốc Bảo",
            unicode"Ứng viên theo đuổi quyền riêng tư, mã nguồn mở và các công cụ phi tập trung trao quyền cho người dùng."
        );

        _addCandidate(
            unicode"Phạm Gia Huy",
            unicode"Nhà phân tích tài chính hướng đến mô hình kinh tế bền vững, công bằng và thực tế cho hệ sinh thái Web3."
        );
    }

    /// Internal Function
    function _addCandidate(string memory _name, string memory _bio) internal {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _bio, 0);
    }

    function _requireValidCandidate(uint _candidateId) internal view {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        require(bytes(candidates[_candidateId].name).length > 0, "Candidate does not exist");
    }

    function _recordVoter(address _voter) internal {
        if (!knownVoter[_voter]) {
            knownVoter[_voter] = true;
            voters.push(_voter);
        }
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
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        require(bytes(candidates[_candidateId].name).length > 0, "Candidate does not exist");
        candidates[_candidateId].name = _name;
        candidates[_candidateId].bio = _bio;
        emit candidateUpdated(_candidateId, _name, _bio);
    }

    function deleteCandidate(uint _candidateId) public onlyOwner {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        require(bytes(candidates[_candidateId].name).length > 0, "Candidate does not exist");
        delete candidates[_candidateId];
        emit candidateDeleted(_candidateId);
    }

    /// Vote Function
    function vote(uint _candidateId) public withinVotingPeriod {
        require(!hasVoted[msg.sender], "You have already voted");
        _requireValidCandidate(_candidateId);

        hasVoted[msg.sender] = true;
        votedCandidate[msg.sender] = _candidateId;
        _recordVoter(msg.sender);
        candidates[_candidateId].voteCount++;

        emit votedEvent(msg.sender, _candidateId);
    }

    function resetVoter(address _voter) public onlyOwner {
        require(hasVoted[_voter], "Voter has not voted");

        uint oldCandidateId = votedCandidate[_voter];
        if (
            oldCandidateId > 0 &&
            oldCandidateId <= candidatesCount &&
            candidates[oldCandidateId].voteCount > 0
        ) {
            candidates[oldCandidateId].voteCount--;
        }

        hasVoted[_voter] = false;
        votedCandidate[_voter] = 0;

        emit voteReset(_voter, oldCandidateId);
    }

    function getVotersCount() public view returns (uint) {
        return voters.length;
    }

    function getVoterAt(uint _index) public view returns (address) {
        require(_index < voters.length, "Voter index out of bounds");
        return voters[_index];
    }

    function getVotingStatus() public view returns (string memory) {
        if (block.timestamp < startTime) return "NOT_STARTED";
        if (block.timestamp >= startTime && block.timestamp <= endTime) return "ACTIVE";
        return "ENDED";
    }
}
