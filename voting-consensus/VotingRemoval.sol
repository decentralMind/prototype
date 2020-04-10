pragma solidity ^0.5.0;

import "./Community.sol";

contract VotingRemoval is Community {
    /**
     * @dev Voting system for removal of community members and owner
     * and resetting expiry date.
     * Once owner has been removed, new owner cannot be added, thereafter community
     * will be incharge of the smart contract.
     *
     * Removal process requires 51% voting consensus from communities
     * regisered as trusted. {calculateVotingRequired} is responsible for
     * calculating required number of voters.
     *
     * Currently, this contract needs at least 200 communites to be able for  the communities
     * to take control it. This number can be changed by owner anytime.
     */

    //Main format for storing voting data.
    struct VotingData {
        bool isOpen;
        bool isRemoved;
        address openBy;
        uint256 expiryDate;
        uint256 totalVote;
        uint256 voteRequired;
        // `requestedTimeChange` is only used when rquesting removal time frame, removalTimeFrame.
        uint256 requestedTimeChange;
        bytes reason;
        mapping(address => bool) voted;
    }

    // Community removal proposals with address of proposed community to be removed.
    // map to data.
    mapping(address => VotingData) communityRemovalProposal;

    // Record the address of proposals.
    // Will be used to get voting data from `communityRemovalProposal` mapping.
    address[] removalList;

    // All community removed address.
    address[] allRemoved;

    // Voting open for 5 days.
    uint256 public removalTimeFrame = 432000;

    // Minimum amount of registered community members before
    // allowing communities to create proposals and vote.
    uint256 communityNumber = 200;

    // Expiry date change proposals with address of proposals mapped to voting data.
    mapping(address => VotingData) changeTimeFrameProposal;

    // Address of those who have put proposal to change time.
    address[] changeTimeFrameList;

    // Address of those whose time frame proposals was success.
    address[] changeTimeFrameSuccess;

    // Owner removal proposals with address of proposals mapped with voting data.
    mapping(address => VotingData) ownerRemoval;

    // Records the community address who proposed the removal of owner.
    address[] ownerRemovalList;

    // Set true if owner is successfully removed.
    bool ownerRemoved;

    /**
     * @dev Throw if change time frame proposal already expired.
     * Inactive time frame proposal set expiry date to 0 by default.
     * Check for expired time frame proposal.
     */
    modifier timeFrameNotActive(address sender) {
        VotingData memory vd = changeTimeFrameProposal[sender];
        require(vd.expiryDate > block.timestamp || vd.expiryDate == 0, 
        'Current change time frame proposal should not be active');
        _;
    }

    /**
     * @dev Throw if current voting proposal is not opened.
     */
    modifier alreadyListed(address commAdd) {
        VotingData memory vd = communityRemovalProposal[commAdd];
        require(
            !vd.isOpen,
            "Voting proposal is not open, either it closed or has not been registered"
        );
        _;
    }

    /**
     * @dev Throw if current expiry date change proposal
     * by the given community has expired or not open.
     */
    modifier timeFrameRegistered(address openBy) {
        VotingData memory vd = changeTimeFrameProposal[openBy];
        require(
            vd.isOpen && vd.expiryDate > block.timestamp,
            "Current expiry date change proposal already expired or not registerd"
        );
        _;
    }

    /**
     * @dev Throw if minimum total number of required community has not been reached.
     * Minimum required community number is required in order for the community to contral the smart contract
     * without owner.
     * Community should be registered as trusted.
     */
    modifier sufficientCommunityNumber() {
        require(
            trustedCommunity >= communityNumber,
            "Total number of trusted registered community should be greater than what required"
        );
        _;
    }

    /**
     * @dev Throws if owner is already removed.
     */
    modifier isOwnerRemoved() {
        require(!ownerRemoved, "Owner has been already removed");
        _;
    }

    event VotingDataEvent(
        bool isOpen,
        bool isRemoved,
        address openBy,
        uint256 expiryDate,
        uint256 totalVote,
        uint256 voteRequired,
        uint256 newTimeFrame,
        bytes reason
    );

    event CommunityNumberEvent(uint256 newNumber);

    /**
     *@dev Assign minimum `newNumber` requirement for registered communities before
     * allowing them to open proposals and voting.
     *
     * emits a {CommunityNumberEvent}
     */
    function changeCommunityNumber(uint256 newNumber) external onlyOwner {
        communityNumber = newNumber;
        emit CommunityNumberEvent(newNumber);
    }

    /**
     * @dev Open proposal to reset expiry date to `newTimeFrame`  with
     * valid `reason`.
     *
     * Requirements:
     * -Communites must be registered as trusted.
     * -Current proposal creator address should not have other active expiry date
     *  change proposals.
     *
     * emits a {VotingDataEvent}.
     */
    function openVoteTimeFrame(uint256 newTimeFrame, bytes memory reason)
        public
        onlyEligible
        timeFrameNotActive(msg.sender)
        sufficientCommunityNumber
    {
        VotingData storage vd = changeTimeFrameProposal[msg.sender];
        vd.isOpen = true;
        vd.openBy = msg.sender;
        vd.expiryDate = block.timestamp + removalTimeFrame;
        vd.totalVote++;
        vd.voteRequired = calculateVotingRequired();
        vd.requestedTimeChange = newTimeFrame;
        vd.reason = reason;
        vd.voted[msg.sender] = true;

        // Store the array the list.
        changeTimeFrameList.push(msg.sender);

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Vote to reset expiry date proposal `openBy' given community.
     *
     * Requirements:
     * - Current proposal should be active.
     * - Sufficient number of community should be presence.
     * - Only registered trusted communities.
     *
     * emits a {VotingDataEvent}.
     */
    function voteToChangeTimeFrame(address openBy)
        public
        timeFrameRegistered(openBy)
        onlyEligible
        sufficientCommunityNumber
    {
        VotingData storage vd = changeTimeFrameProposal[openBy];
        // Increaset total vote.
        vd.totalVote++;
        // Registered voted address.
        vd.voted[msg.sender] = true;

        // If number of voting requirements met the target, change time frame.
        if (vd.totalVote >= vd.voteRequired) {
            vd.isOpen = false;
            vd.isRemoved = true;
            removalTimeFrame = vd.requestedTimeChange;
            changeTimeFrameSuccess.push(openBy);
        }

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Open proposal to remove community address `commAdd1` because of 'reason'.
     * Requirements:
     * -Only trusted registered communities.
     * -Should not be already listed for removal.
     * -Sufficient number of communities should be presence.
     *
     * emits a {VotingDataEvent}.
     */
    function openCommunityRemoval(address commAdd, bytes memory reason)
        public
        onlyEligible
        alreadyListed(commAdd)
        sufficientCommunityNumber
    {
        VotingData storage vd = communityRemovalProposal[commAdd];
        vd.expiryDate = now + removalTimeFrame;
        vd.openBy = msg.sender;
        vd.reason = reason;
        vd.isOpen = true;
        vd.voteRequired = calculateVotingRequired();
        vd.voted[msg.sender] = true;

        removalList.push(commAdd);

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Vote for community `commAdd` removal.
     * Requirements:
     * - Current proposal must be active and open.
     * - Sufficient number of communities should be presence.
     * - Given address can only vote once.
     *
     * emits a {VotingDataEvent}.
     */
    function voteForCommunityRemoval(address commAdd) external onlyEligible {
        VotingData storage vd = communityRemovalProposal[commAdd];
        // require(vd.isOpen);
        // require(!vd.voted[msg.sender]);
        vd.voted[msg.sender] = true;
        vd.expiryDate = block.timestamp + removalTimeFrame;
        vd.totalVote++;

        // Remove community member if voting required target is met.
        if (vd.totalVote >= vd.voteRequired) {
            _removeCommunity(commAdd);
            allRemoved.push(commAdd);
        }

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Request to remove owner. Once owner is removed, new owner cannot be added.
     * Requirements:
     * - Only trusted communities.
     * - Sufficient number of communities should be presence.
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
        require(!_previousOwnerRemovalActive(),
         'Currently owner removal proposal is active from this address');

        VotingData storage vd = ownerRemoval[openBy];
        vd.expiryDate = now + removalTimeFrame;
        vd.openBy = msg.sender;
        vd.reason = reason;
        vd.isOpen = true;

        //51% of the trusted registered community consensus is required.
        vd.voteRequired = calculateVotingRequired();
        vd.voted[msg.sender] = true;
        ownerRemovalList.push(openBy);

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Vote to remove owner, once owner is removed it cannot be added,
     * thereafter trusted registered communities will be in charge.
     *
     * Requirements:
     * - Only trusted communities.
     * - Sufficient number of communities should be presence.
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

        // Sender has not voted already.
        require(!vd.voted[msg.sender], "This address has already voted");
        vd.voted[msg.sender] = true;
        vd.totalVote++;

        // If vote required satisfies than owner address is set to 0;
        if (vd.totalVote >= vd.voteRequired) {
            require(_removeOwner(), 'Owner is not removed');
            vd.isRemoved = true;
        }

        emit VotingDataEvent(
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

    /**
     * @dev Returns proposal creator address by given `index`.
     */
    function getOwnerRemovalList(uint256 index) public view returns (address) {
        require(
            ownerRemovalListLength() > 0,
            "No active owner removal proposals."
        );
        return ownerRemovalList[index];
    }

    /**
     * @dev Returns {ownerRemovalList} length.
     */
    function ownerRemovalListLength() public view returns (uint256) {
        return ownerRemovalList.length;
    }

    /**
     * @dev Check if the previous owner removal request expired. If already expired, resets it.
     * @return bool true if active and false if not active.
     * */
    function _previousOwnerRemovalActive() private returns (bool) {
        // Get the data of removal request submitted by the given address.
        // {OwnerRemovalList} always update the current active removal request.
        VotingData storage vd = ownerRemoval[getOwnerRemovalList(
            ownerRemovalListLength() - 1
        )];

        if (vd.isOpen == false) {
            return false;
        }

        if (vd.expiryDate < block.timestamp) {
            vd.isOpen = false;
            return false;
        }

        return true;
    }

    /**
     * @dev Remove the owner from the contract.
     * Onwer cannot be added once it's removed.
     * After owner is removed trusted registered communities
     * will be in charge of the this contract.
     */
    function _removeOwner() private returns (bool) {
        _replaceOwner(address(0));
        ownerRemoved = true;
        return ownerRemoved;
    }

    /**
     * @dev Get the number of voting numbers required for the
     * prosposal to be successful.
     *
     * 51% of total reqistered trusted community consensus is required.
     * Exactly 51% of voting number required cannot be achieved if
     * total Community modulus 100 is not equal zero, so in that case adding
     * 1 in the {calculateVotingRequired} gives the percentage different of
     * around 1 percent, so actualy percentage will be between 51% and 52%.
     * If more communities are added, the less the gap in the percentage difference
     * and more accuracy towards 51% target.
     *
     * @return number of voting required.
     *
     */
    function calculateVotingRequired() public view returns (uint) {
        if (trustedCommunity % 100 == 0) {
            return _votingPercentage();
        } else {
            return (_votingPercentage() + 1);
        }
    }

    /**
     * @dev Returns 51% of total registered trusted community.
     */
    function _votingPercentage() private view returns (uint) {
        return (trustedCommunity * 51) / 100;
    }

    /**
     * @dev Returns `removalList` size, which contains the address of
     * those who have created proposals.
     */
    function removalListSize() public view returns (uint) {
        return removalList.length;
    }

    /**
     * @dev Returns `allRemoved` size, which contains the address of
     * communities that has been removed.
     */
    function allRemovedSize() public view returns (uint) {
        return allRemoved.length;
    }

    /**
     * @dev Returns community removal creator address
     * directly through `index` access.
     */
    function getcommunityRemovalProposalAddress(uint index) public view returns (address) {
        return removalList[index];
    }

    /**
     * @dev Returns address of community which has been removed
     * directly through `index` access.
     */
    function getRemovedAddress(uint index) public view returns (address) {
        return allRemoved[index];
    }

    /**
     * @dev Returns length of `changeTimeFrameList`.
     */
    function getChangeTimeFrameList() public view returns (uint) {
        return changeTimeFrameList.length;
    }

    /**
     * @dev Returns true if change time frame proposal is open and vice versa.
     */
    function isTimeFrameProposalOpen(address openBy)
        public
        view
        returns (bool)
    {
        VotingData memory vd = changeTimeFrameProposal[openBy];

        // Checks if proposal is open.
        // Checks if proposal already expired.
        if (!vd.isOpen || vd.expiryDate <= block.timestamp) {
            return false;
        }
        return true;
    }

    /**
     * @dev Returns total voting receiver for Tiem frame change proposal.
     */
    function getChangeTimeFrameVoteCount(address openBy)
        public
        view
        returns (uint)
    {
        VotingData storage vd = changeTimeFrameProposal[openBy];
        return vd.totalVote;
    }

    /**
     * @dev Returns `changeTimeFrameSuccess` length.
     */
    function getChangeTimeFrameSuccessLength() external view returns(uint) {
        return changeTimeFrameSuccess.length;
    }

    /**
     * @dev Returns total voting receiver for Tiem frame change proposal.
     */
    function getCommunityRemovalVote(address removalCommunity)
        public
        view
        returns (uint)
    {
        VotingData storage vd = communityRemovalProposal[removalCommunity];
        return vd.totalVote;
    }

    /**
     * @dev Returns `communityNumber`.
     */
    function getCommunityNumber() public view returns (uint256) {
        return communityNumber;
    }

    function getTimeFrameChangeData(address createdBy)
        public
        view
        returns (
            bool getIsOpen,
            bool getIsRemoved,
            address getOpenBy,
            uint256 getExpiryDate,
            uint256 getTotalVote,
            uint256 getVoteRequired,
            uint256 getRequestedTimeChange,
            bytes memory getReason
        )
    {
        VotingData memory vd = changeTimeFrameProposal[createdBy];
        return (
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }

     function getCommunityRemovalData(address community)
        public
        view
        returns (
            bool getIsOpen,
            bool getIsRemoved,
            address getOpenBy,
            uint256 getExpiryDate,
            uint256 getTotalVote,
            uint256 getVoteRequired,
            uint256 getRequestedTimeChange,
            bytes memory getReason
        )
    {
        VotingData memory vd = communityRemovalProposal[community];
        return (
            vd.isOpen,
            vd.isRemoved,
            vd.openBy,
            vd.expiryDate,
            vd.totalVote,
            vd.voteRequired,
            vd.requestedTimeChange,
            vd.reason
        );
    }
}
