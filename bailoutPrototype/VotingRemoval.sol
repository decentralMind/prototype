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

    address[] removalList;
    address[] allRemoved;

    //Voting open for 5 days.
    uint public removalTimeFrame = 432000;
    
    uint communityNumber = 200;

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
    
    modifier sufficientCommuintyNumber() {
        require(trustedCommunity >= 200);
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
    
    event CommunityNumberEvent(
        uint newNumber
        );
    
    function changeCommunityNumber(uint newNumber) external onlyOwner {
        communityNumber = newNumber;
        emit CommunityNumberEvent(newNumber);
    }
    

    function openVoteTimeFrame(bytes memory reason, uint256 newTimeFrame)
        public
        onlyEligible
        alreadyTimeFrameRegistered
        sufficientCommuintyNumber
    {
        VotingData storage vd = changeTimeFrame[msg.sender];
        vd.isOpen = true;
        vd.openedBy = msg.sender;
        vd.expiryDate = now + removalTimeFrame;
        vd.totalVote++;
        vd.voteRequired = _calculateVotingRequired();
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
        sufficientCommuintyNumber
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

    function addToRemovalList(address commAdd, bytes memory reason)
        public
        onlyEligible
        alreadyListed(commAdd)
        sufficientCommuintyNumber
    {
        VotingData storage ld = redList[commAdd];
        ld.expiryDate = now + removalTimeFrame;
        ld.openedBy = msg.sender;
        ld.reason = reason;
        ld.isOpen = true;
        ld.voteRequired = _calculateVotingRequired();
        ld.voted[msg.sender] = true;

        removalList.push(commAdd);
        emit RedListEvent(
            msg.sender,
            commAdd,
            ld.expiryDate,
            ld.isOpen,
            ld.reason
        );
    }

    function voteForCommunityRemoval(address commAdd) public onlyEligible {
        VotingData storage ld = redList[commAdd];
        require(!ld.voted[msg.sender]);
        ld.voted[msg.sender] = true;
        ld.expiryDate = block.timestamp + removalTimeFrame;
        ld.totalVote++;

        if (ld.totalVote >= ld.voteRequired) {
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
    
    function voteToRemoveOwner() onlyEligible public {
        //onlyElibible are able to vote.
        //
            
    }
    
    function _calculateVotingRequired() private view returns (uint) {
        if(trustedCommunity % 100 == 0) {
            return _votingPercentage();
        } else {
            return (_votingPercentage() + 1);
        }
    }

    function _votingPercentage() private view returns(uint) {
        return trustedCommunity * 51/100;
    }
    
    function removalListSize() public view returns (uint256) {
        return removalList.length;
    }

    function allRemovedSize() public view returns (uint256) {
        return allRemoved.length;
    }

    function getRedListedAddress(uint256 index) public view returns (address) {
        return removalList[index];
    }

    function getAllRemovedAddress(uint256 index) public view returns (address) {
        return allRemoved[index];
    }
}
