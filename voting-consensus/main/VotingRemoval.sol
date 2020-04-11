pragma solidity ^0.5.0;

import "./CommunityRemoval.sol";


contract VotingRemoval is CommunityRemoval {
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
     *
     *
     * Todo:
     *
     * Owner removal through voting consensus needs to be implemented.
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
        string reason;
        mapping(address => bool) voted;
    }

    // Community removal proposals with address of proposed community to be removed.
    // map to data.
    mapping(address => VotingData) private _communityRemovalProposal;

    // Record the address of proposals.
    // Will be used to get voting data from `_communityRemovalProposal` mapping.
    address[] private _removalList;

    // All community removed address.
    address[] private _allRemoved;

    // Voting open for 5 days.
    uint256 public removalTimeFrame = 432000;

    // Minimum amount of registered community members before
    // allowing communities to create proposals and vote.
    uint256 private _communityNumber = 200;

    // Expiry date change proposals with address of proposals mapped to voting data.
    mapping(address => VotingData) private _changeTimeFrameProposal;

    // Address of those who have put proposal to change time.
    address[] private _changeTimeFrameList;

    // Address of those whose time frame proposals was success.
    address[] private _changeTimeFrameSuccess;

    /**
     * @dev Throw if change time frame proposal already expired.
     * Inactive time frame proposal set expiry date to 0 by default.
     * Check for expired time frame proposal.
     */
    modifier timeFrameNotActive(address sender) {
        VotingData memory vd = _changeTimeFrameProposal[sender];
        require(
            vd.expiryDate > block.timestamp || vd.expiryDate == 0,
            "Current change time frame proposal should not be active"
        );
        _;
    }

    /**
     * @dev Throw if current voting proposal is not opened.
     */
    modifier alreadyListed(address commAdd) {
        VotingData memory vd = _communityRemovalProposal[commAdd];
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
        VotingData memory vd = _changeTimeFrameProposal[openBy];
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
            _trustedCommunity >= _communityNumber,
            "Total number of trusted registered community should be greater than what required"
        );
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
        string reason
    );

    event communityNumberEvent(uint256 newNumber);

    /**
     *@dev Assign minimum `newNumber` requirement for registered communities before
     * allowing them to open proposals and voting.
     *
     * emits a {communityNumberEvent}
     */
    function changeCommunityNumber(uint256 newNumber) external onlyOwner {
        _communityNumber = newNumber;
        emit communityNumberEvent(newNumber);
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
    function openVoteTimeFrame(uint256 newTimeFrame, string calldata reason)
        external
        onlyEligible
        timeFrameNotActive(msg.sender)
        sufficientCommunityNumber
    {
        VotingData storage vd = _changeTimeFrameProposal[msg.sender];
        vd.isOpen = true;
        vd.openBy = msg.sender;
        vd.expiryDate = block.timestamp + removalTimeFrame;
        vd.totalVote++;
        vd.voteRequired = calculateVotingRequired();
        vd.requestedTimeChange = newTimeFrame;
        vd.reason = reason;
        vd.voted[msg.sender] = true;

        // Store the array the list.
        _changeTimeFrameList.push(msg.sender);

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
        external
        timeFrameRegistered(openBy)
        onlyEligible
        sufficientCommunityNumber
    {
        VotingData storage vd = _changeTimeFrameProposal[openBy];
        // Increase total vote.
        vd.totalVote++;
        // Registered voted address.
        vd.voted[msg.sender] = true;

        // If number of voting requirements met the target, change time frame.
        if (vd.totalVote >= vd.voteRequired) {
            vd.isOpen = false;
            vd.isRemoved = true;
            removalTimeFrame = vd.requestedTimeChange;
            _changeTimeFrameSuccess.push(openBy);
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
    function openCommunityRemoval(address commAdd, string calldata reason)
        external
        onlyEligible
        alreadyListed(commAdd)
        sufficientCommunityNumber
    {
        VotingData storage vd = _communityRemovalProposal[commAdd];
        vd.expiryDate = now + removalTimeFrame;
        vd.openBy = msg.sender;
        vd.reason = reason;
        vd.isOpen = true;
        vd.voteRequired = calculateVotingRequired();
        vd.voted[msg.sender] = true;

        _removalList.push(commAdd);

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
        VotingData storage vd = _communityRemovalProposal[commAdd];
        // require(vd.isOpen);
        // require(!vd.voted[msg.sender]);
        vd.voted[msg.sender] = true;
        vd.expiryDate = block.timestamp + removalTimeFrame;
        vd.totalVote++;

        // Remove community member if voting required target is met.
        if (vd.totalVote >= vd.voteRequired) {
            vd.isOpen = false;
            vd.isRemoved = true;
            _allRemoved.push(commAdd);
            _removeCommunity(commAdd);
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
    function calculateVotingRequired() public view returns (uint256) {
        if (_trustedCommunity % 100 == 0) {
            return _votingPercentage();
        } else {
            return (_votingPercentage() + 1);
        }
    }

    /**
     * @dev Returns 51% of total registered trusted community.
     */
    function _votingPercentage() private view returns (uint256) {
        return (_trustedCommunity * 51) / 100;
    }

    /**
     * @dev Returns `_removalList` size, which contains the address of
     * those who have created proposals.
     */
    function removalListSize() external view returns (uint256) {
        return _removalList.length;
    }

    /**
     * @dev Returns `_allRemoved` size, which contains the address of
     * communities that has been removed.
     */
    function allRemovedSize() external view returns (uint256) {
        return _allRemoved.length;
    }

    /**
     * @dev Returns community removal creator address
     * directly through `index` access.
     */
    function getCommunityRemovalProposalAddress(uint256 index)
        external
        view
        returns (address)
    {
        return _removalList[index];
    }

    /**
     * @dev Returns address of community which has been removed
     * directly through `index` access.
     */
    function getRemovedAddress(uint256 index) external view returns (address) {
        return _allRemoved[index];
    }

    /**
     * @dev Returns length of `_changeTimeFrameList`.
     */
    function getChangeTimeFrameList() external view returns (uint256) {
        return _changeTimeFrameList.length;
    }

    /**
     * @dev Returns true if change time frame proposal is open and vice versa.
     */
    function isTimeFrameProposalOpen(address openBy)
        public
        view
        returns (bool)
    {
        VotingData memory vd = _changeTimeFrameProposal[openBy];

        // Checks if proposal is open.
        // Checks if proposal already expired.
        if (!vd.isOpen || vd.expiryDate <= block.timestamp) {
            return false;
        }
        return true;
    }

    /**
     * @dev Returns total voting receiver for Time frame change proposal.
     */
    function getChangeTimeFrameVoteCount(address openBy)
        external
        view
        returns (uint256)
    {
        VotingData storage vd = _changeTimeFrameProposal[openBy];
        return vd.totalVote;
    }

    /**
     * @dev Returns `_changeTimeFrameSuccess` length.
     */
    function getChangeTimeFrameSuccessLength() external view returns (uint256) {
        return _changeTimeFrameSuccess.length;
    }

    /**
     * @dev Returns total voting receiver for Tiem frame change proposal.
     */
    function getCommunityRemovalVote(address removalCommunity)
        external
        view
        returns (uint256)
    {
        VotingData storage vd = _communityRemovalProposal[removalCommunity];
        return vd.totalVote;
    }

    /**
     * @dev Returns `_communityNumber`.
     */
    function getCommunityNumber() external view returns (uint256) {
        return _communityNumber;
    }

    function getTimeFrameChangeData(address createdBy)
        external
        view
        returns (
            bool getIsOpen,
            bool getIsRemoved,
            address getOpenBy,
            uint256 getExpiryDate,
            uint256 getTotalVote,
            uint256 getVoteRequired,
            uint256 getRequestedTimeChange,
            string memory getReason
        )
    {
        VotingData memory vd = _changeTimeFrameProposal[createdBy];
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
        external
        view
        returns (
            bool getIsOpen,
            bool getIsRemoved,
            address getOpenBy,
            uint256 getExpiryDate,
            uint256 getTotalVote,
            uint256 getVoteRequired,
            uint256 getRequestedTimeChange,
            string memory getReason
        )
    {
        VotingData memory vd = _communityRemovalProposal[community];
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
