pragma solidity ^0.5.0;

import "./Community.sol";


contract VotingRemoval is Community {
    //Conseus needs to build in every way.

    //get current list of removal community
    struct VotingData {
        bool isOpen;
        bool isRemoved;
        address openedBy;
        uint256 expiryDate;
        uint256 totalVote;
        uint256 voteRequired;
        // This is only used when rquesting removal time frame, removalTimeFrame.
        uint256 requestedTimeChange;
        bytes reason;
        mapping(address => bool) voted;
    }

    mapping(address => VotingData) redList;

    address[] allRedListed;
    address[] allRemoved;


    //Voting open for 5 days.
    uint256 public removalTimeFrame = 432000;

    mapping(address => VotingData) changeTimeFrame;
    //get the current list based one date

    modifier alreadyListed(address commAdd) {
        VotingData memory vd = redList[commAdd];
        require(!vd.isOpen);
        _;
    }

    modifier alreadyTimeFrameRegistered() {
        VotingData memory vd = changeTimeFrame[msg.sender];
        require(!vd.isOpen);
        _;
    }

    modifier timeFrameRegistered(address openBy) {
        VotingData memory vd = changeTimeFrame[openBy];
        require(vd.isOpen);
        _;
    }

    event RedListEvent(
        address deployer,
        address community,
        uint256 expiryDate,
        bool isOpen,
        bytes reason
    );

    event VotingEvent(
        address voter,
        address community,
        uint256 expiryDate,
        uint256 totalVote,
        uint256 votingRequired,
        bool isOpen,
        bool isRemoved
    );

    event TimeFrameEvent(
        bool isOpen,
        bool isRemoved,
        address openedBy,
        uint256 expiryDate,
        uint256 totalVote,
        uint256 voteRequired,
        uint256 newTimeFrame,
        bytes reason
    );

    event ChangeTimeFrameEvent(
        bool isOpen,
        bool isRemoved,
        address openedBy,
        uint256 expiryDate,
        uint256 totalVote,
        uint256 voteRequired,
        uint256 newTimeFrame,
        bytes reason
    );

    function openVoteTimeFrame(bytes memory reason, uint256 newTimeFrame)
        public
        onlyEligible
        alreadyTimeFrameRegistered
    {
        VotingData storage vd = changeTimeFrame[msg.sender];
        vd.isOpen = true;
        vd.openedBy = msg.sender;
        vd.expiryDate = now + removalTimeFrame;
        vd.totalVote++;
        vd.voteRequired = calculateVotingRequired();
        vd.requestedTimeChange = newTimeFrame;
        vd.reason = reason;
        vd.voted[msg.sender] = true;

        emit TimeFrameEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openedBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    function voteToChangeTimeFrame(address openedBy)
        public
        timeFrameRegistered(openedBy)
        onlyEligible
    {
        VotingData storage vd = changeTimeFrame[openedBy];
        // Increaset total vote.
        vd.totalVote++;
        // Registered voted address.
        vd.voted[msg.sender] = true;

        // If number of voting met the target
        if (vd.totalVote >= vd.voteRequired) {
            vd.isOpen = false;
            vd.isRemoved = true;
            removalTimeFrame = vd.requestedTimeChange;
        }

        emit ChangeTimeFrameEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openedBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    function addToRedList(address commAdd, bytes memory reason)
        public
        onlyEligible
        alreadyListed(commAdd)
    {
        VotingData storage ld = redList[commAdd];
        ld.expiryDate = now + removalTimeFrame;
        ld.openedBy = msg.sender;
        ld.reason = reason;
        ld.isOpen = true;
        ld.voteRequired = calculateVotingRequired();
        ld.voted[msg.sender] = true;

        allRedListed.push(commAdd);
        emit RedListEvent(
            msg.sender,
            commAdd,
            ld.expiryDate,
            ld.isOpen,
            ld.reason
        );
    }

    function voteForRemoval(address commAdd) public onlyEligible {
        VotingData storage ld = redList[commAdd];
        require(!ld.voted[msg.sender]);
        ld.voted[msg.sender] = true;
        ld.expiryDate = block.timestamp + removalTimeFrame;
        ld.totalVote++;

        //this about the negative here.
        if (ld.totalVote > ld.voteRequired || ld.totalVote == ld.voteRequired) {
            removeCommunity(commAdd);
            allRemoved.push(commAdd);
        }

        emit VotingEvent(
            msg.sender,
            commAdd,
            ld.expiryDate,
            ld.totalVote,
            ld.voteRequired,
            ld.isOpen,
            ld.isRemoved
        );
    }

    // function _addStructTotal() private {
        
    // }

    function calculateVotingRequired() public view returns (uint256) {
        return (((trustedCommunity + 1) * 51) / 100) * 100;
    }

    function allRedListedSize() public view returns (uint256) {
        return allRedListed.length;
    }

    function allRemovedSize() public view returns (uint256) {
        return allRemoved.length;
    }

    function getRedListedAddress(uint256 index) public view returns (address) {
        return allRedListed[index];
    }

    function getAllRemovedAddress(uint256 index) public view returns (address) {
        return allRemoved[index];
    }
}
