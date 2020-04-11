pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../VotingRemoval.sol";

contract OpenVotingChange {
    VotingRemoval vr;
    address deployAdd;
   
    function beforeAll() public {
        vr = new VotingRemoval();
        deployAdd = address(this);
        
        vr.changeCommunityNumber(1);
        
        vr.addCommunity(TestsAccounts.getAccount(0));
        vr.directlyTrustedByOwner(TestsAccounts.getAccount(0));
    }
    
    function successfullyOpenProposalToChangeTimeFrame() public {
         vr.openVoteTimeFrame(3, "Some reason");
        ( 
        bool isOpen,
        bool isRemoved,
        address openBy,
        uint expiryDate,
        uint totalVote,
        uint voteRequired,
        uint requestedTimeChange,
        
        ) = vr.getTimeFrameChangeData(deployAdd);

        Assert.equal(isOpen, true, 'Should be true.');
        Assert.equal(isRemoved, false, 'Should be false.');
        Assert.equal(openBy, deployAdd, 'Creator address should match.');
        
        // // +- 5 seconds internval.
        Assert.greaterThan(expiryDate, vr.removalTimeFrame() + block.timestamp - 5, 'ExpiryDate is set correctly in future.');
        Assert.equal(totalVote, 1, 'Total number of vote should be 1 at initial.');
        Assert.equal(voteRequired, 1, 'Vote required should match.');
        Assert.equal(requestedTimeChange, 3, 'Should be supplied value 3.');
        
        Assert.equal(vr.getChangeTimeFrameList(), 1, 'changeTimeFrameList must be update to length of 1.');
    }

}
