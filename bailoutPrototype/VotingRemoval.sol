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
    uint256 public removalTimeFrame = 432000;

    uint256 communityNumber = 200;

    mapping(address => VotingData) changeTimeFrame;
    //get the current list based one date

    mapping(address => VotingData) ownerRemoval;

    address[] ownerRemovalList;

    bool ownerRemoved;

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

    modifier sufficientCommunityNumber() {
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

    event CommunityNumberEvent(uint256 newNumber);

    event VotingDataEvent(
        bool isOpen,
        bool isRemoved,
        address openedBy,
        uint256 expiryDate,
        uint256 totalVote,
        uint256 voteRequired,
        uint256 newTimeFrame,
        bytes reason
    );

    function changeCommunityNumber(uint256 newNumber) external onlyOwner {
        communityNumber = newNumber;
        emit CommunityNumberEvent(newNumber);
    }

    function openVoteTimeFrame(bytes memory reason, uint256 newTimeFrame)
        public
        onlyEligible
        alreadyTimeFrameRegistered
        sufficientCommunityNumber
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
        sufficientCommunityNumber
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
        sufficientCommunityNumber
    {
        VotingData storage vd = redList[commAdd];
        vd.expiryDate = now + removalTimeFrame;
        vd.openedBy = msg.sender;
        vd.reason = reason;
        vd.isOpen = true;
        vd.voteRequired = _calculateVotingRequired();
        vd.voted[msg.sender] = true;

        removalList.push(commAdd);
        emit RedListEvent(
            msg.sender,
            commAdd,
            vd.expiryDate,
            vd.isOpen,
            vd.reason
        );
    }

    function voteForCommunityRemoval(address commAdd) public onlyEligible {
        VotingData storage vd = redList[commAdd];
        require(!vd.voted[msg.sender]);
        vd.voted[msg.sender] = true;
        vd.expiryDate = block.timestamp + removalTimeFrame;
        vd.totalVote++;

        if (vd.totalVote >= vd.voteRequired) {
            removeCommunity(commAdd);
            allRemoved.push(commAdd);
        }

        emit VotingEvent(
            msg.sender,
            commAdd,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.isOpen,
            vd.isRemoved
        );
    }

    modifier isOwnerRemoved() {
        require(!ownerRemoved);
        _;
    }

    modifier removalListPresence() {
        require(ownerRemovalList.length > 0);
        _;
    }

    function getOwnerRemovalList(uint256 index)
        public
        view
        removalListPresence
        returns (address)
    {
        return ownerRemovalList[index];
    }

    function ownerRemovalListLength() public view returns (uint256) {
        return ownerRemovalList.length;
    }

    /**
     * @dev Request to remove owner. Once owner is removed, new owner cannot be added.
     * Requirements:
     * - Only trusted communities.
     * - Sufficient number of community should be presence.
     * - Owner is not removed.
     * - There should not be active owner removal request.
     *
     * emits a {VotingDataEvent}
     */
    function requestOwnerRemoval(address openBy, bytes calldata reason)
        external
        onlyEligible
        sufficientCommunityNumber
        isOwnerRemoved
    {
        // Check if previous owner removal request is still active.
        require(!_previousOwnerRemovalActive());
        VotingData storage vd = ownerRemoval[openBy];
        vd.expiryDate = now + removalTimeFrame;
        vd.openedBy = msg.sender;
        vd.reason = reason;
        vd.isOpen = true;

        //51% of the trusted registered community consensus is required.
        vd.voteRequired = _calculateVotingRequired();
        vd.voted[msg.sender] = true;
        ownerRemovalList.push(openBy);

        emit VotingDataEvent(
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

    /**
     * @dev Vote to remove owner, once owner is removed it cannot be added. Community will be in charge.
     *
     * Requirements:
     * - Only trusted communities.
     * - Sufficient number of community should be presence.
     * - Owner is not removed.
     * - Current owner removal request should be active.
     * - Sender has not voted already.
     *
     * emits a {VotingDataEvent}.
     */
    function voteForOwnerRemoval(address commAdd)
        external
        onlyEligible
        sufficientCommunityNumber
        isOwnerRemoved
    {
        VotingData storage vd = ownerRemoval[commAdd];

        // Current removal request need to be active.
        require(vd.isOpen, "Current owner removal request is not active");

        // Sender has not vote already.
        require(!vd.voted[msg.sender], "This address has already voted");
        vd.voted[msg.sender] = true;
        vd.totalVote++;

        if (vd.totalVote >= vd.voteRequired) {
            _removeOwner();
            assert(ownerRemoved == true);
            vd.isRemoved = true;
        }

        emit VotingDataEvent(
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

    /**
     * @dev Check if the previous owner removal request expired. If already expired, resets it.
     * OwnerRemovalList always update the current active removal request at last index.
     * @return bool true if active and false if not active.
     * */
    function _previousOwnerRemovalActive() private returns (bool) {
        // Get the data of removal request submitted by the given address.
        // OwnerRemovalList always update the current active removal request at last index.
        VotingData storage vd = ownerRemoval[getOwnerRemovalList(
            ownerRemovalListLength() - 1
        )];

        if (vd.isOpen == false) {
            return false;
        }

        if (vd.expiryDate < now) {
            vd.isOpen = false;
            return false;
        }

        return true;
    }

    /**
     * @dev Remove the owner from the contract.
     * Onwer cannot be added once it's removed.
     * Trusted community will be in charge of the this contract.
     */
    function _removeOwner() private {
        replaceOwner(address(0));
        ownerRemoved = true;
    }

    function _calculateVotingRequired() private view returns (uint256) {
        if (trustedCommunity % 100 == 0) {
            return _votingPercentage();
        } else {
            return (_votingPercentage() + 1);
        }
    }

    function _votingPercentage() private view returns (uint256) {
        return (trustedCommunity * 51) / 100;
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
