//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Governance {
    enum Choice {
        For,
        Against,
        Abstain
    }

    struct Vote {
        address voterAddress;
        Choice choice;
    }
    struct Voter {
        string voterName;
        bool voted;
    }

    uint256 private countResult = 0;
    uint256 public totalVoter = 0;
    uint256 public totalVote = 0;

    uint256 private keepTrackFor = 0;
    uint256 private keepTrackAgainst = 0;
    uint256 private keepTrackAbstain = 0;

    address public ballotOfficialAddress;
    string public proposal;
    uint256 public minVoters;
    uint256 public notResolvedLower;
    uint256 public notResolvedHigher;
    uint256 public startDate;
    uint256 public endDate;

    mapping(uint256 => Vote) private votes;
    mapping(address => Voter) public voterRegister;
    bool public whiteList;

    enum State {
        Created,
        Voting,
        Ended
    }
    State public state;

    modifier onlyOfficial() {
        require(msg.sender == ballotOfficialAddress, "Sender not authorized.");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Wrong action for current state");
        _;
    }

    modifier isWhiteList() {
        require(whiteList == true, "Can't add voter to whiteList");
        _;
    }
    modifier openVoting() {
        require(block.timestamp <= startDate, "Can't start voting yet");
        _;
    }
    modifier closeVoting() {
        require(block.timestamp >= endDate, "Can't close voting yet");
        _;
    }

    constructor(
        string memory _proposal,
        uint256 _notResolvedLower,
        uint256 _notResolvedHigher,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _minVoters,
        bool _whiteList
    ) {
        ballotOfficialAddress = msg.sender;
        proposal = _proposal;
        notResolvedLower = _notResolvedLower;
        notResolvedHigher = _notResolvedHigher;
        startDate = _startDate;
        endDate = _endDate;
        minVoters = _minVoters;
        whiteList = _whiteList;

        state = State.Created;
    }

    function addVoter(address _voterAddress, string memory _voterName)
        public
        inState(State.Created)
        onlyOfficial
        isWhiteList
    {
        Voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter++;
    }

    //forTime openVoting
    function startVote() public inState(State.Created) onlyOfficial {
        state = State.Voting;
    }

    function doVote(uint256 _choice)
        public
        inState(State.Voting)
        returns (bool voted)
    {
        Choice newChoice;
        if (_choice == 0) {
            keepTrackFor++;
            newChoice = Choice.For;
        }
        if (_choice == 1) {
            keepTrackAgainst++;
            newChoice = Choice.Against;
        }
        if (_choice == 2) {
            keepTrackAbstain++;
            newChoice = Choice.Abstain;
        }
        bool found = false;
        if (whiteList) {
            if (
                bytes(voterRegister[msg.sender].voterName).length != 0 &&
                !voterRegister[msg.sender].voted
            ) {
                voterRegister[msg.sender].voted = true;
                Vote memory v;
                v.voterAddress = msg.sender;
                v.choice = newChoice;

                countResult++;

                votes[totalVote] = v;
                totalVote++;
                found = true;
            }
        } else {
            Voter memory voter;
            voter.voterName = "Anon";
            voter.voted = true;
            voterRegister[msg.sender] = voter;
            totalVoter++;

            Vote memory v;
            v.voterAddress = msg.sender;
            v.choice = newChoice;

            countResult++;

            votes[totalVote] = v;
            totalVote++;
            found = true;
        }

        return found;
    }

    //closeVoting
    function endVote() public inState(State.Voting) onlyOfficial {
        state = State.Ended;
    }

    function updateParameters(
        uint256 _notResolvedLower,
        uint256 _notResolvedHigher,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _minVoters
    ) public onlyOfficial {
        notResolvedLower = _notResolvedLower;
        notResolvedHigher = _notResolvedHigher;
        startDate = _startDate;
        endDate = _endDate;
        minVoters = _minVoters;
    }

    //closeVoting
    function finalResultDescription()
        public
        view
        inState(State.Ended)
        onlyOfficial
        returns (string memory description)
    {
        if (minVoters > totalVoter) return "To small people voted...";
        uint256 votedForProcent = (keepTrackFor * 100) / countResult;
        uint256 votedAgainstProcent = (keepTrackAgainst * 100) / countResult;
        uint256 votedAbstainProcent = (keepTrackAbstain * 100) / countResult;
        if(votedForProcent > notResolvedHigher) return "Vote resolved positive";
        if(votedForProcent > votedAgainstProcent && votedForProcent > votedAbstainProcent){
          return "Most voted: For !";
        }
        if(votedAgainstProcent > votedForProcent && votedAgainstProcent > votedAbstainProcent){
          return "Most voted: Against";
        }
        if(votedAbstainProcent > votedForProcent && votedAbstainProcent > votedAgainstProcent){
          return "Most boted: Abstain";
        }
        return "vote not resolved";
    }
}
