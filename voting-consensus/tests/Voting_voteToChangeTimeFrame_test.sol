pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../main/VotingRemoval.sol";


contract voteToChangeTimeFrame {
    VotingRemoval vr;
    address deployAdd;

    function beforeAll() public {
        vr = new VotingRemoval();
        deployAdd = address(this);
        vr.changeCommunityNumber(0);
    }

    function successfullyVoteToChangeTimeFrame() public {
        vr.openVoteTimeFrame(3, "Some reason");
        vr.voteToChangeTimeFrame(deployAdd);
        (
            bool isOpen,
            bool isRemoved,
            address openBy,
            uint256 expiryDate,
            uint256 totalVote,
            uint256 voteRequired,
            uint256 requestedTimeChange,

        ) = vr.getTimeFrameChangeData(deployAdd);

        Assert.equal(isOpen, false, "Should be true.");
        Assert.equal(isRemoved, true, "Should be false.");
        Assert.equal(totalVote, 2, "Total vote should be 2.");

        Assert.equal(
            vr.getChangeTimeFrameSuccessLength(),
            1,
            "changeTimeFrameSuccess length must be 1."
        );
    }
}
