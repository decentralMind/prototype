pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../main/VotingRemoval.sol";


contract CommunityRemovalTest {
    VotingRemoval vr;
    address deployAdd;

    address acc0;
    address acc1;

    function beforeAll() public {
        vr = new VotingRemoval();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        deployAdd = address(this);
       
        vr.addCommunity(acc1);
        vr.directlyTrustedByOwner(acc1);

        vr.changeCommunityNumber(1);
        
        vr.mint(100);
        vr.transfer(50, acc1);
    }

    function shouldSuccessfullyTransferTheBalance() public {
        Assert.equal(vr.balanceOf(acc1), 50, 'Account must be loaded wtih correct balance.');
    }
    
    function shouldSuccessfullyOpenCommunityRemovalProposal() public {
        string memory someReason = "Create token against community will";
        vr.openCommunityRemoval(acc1, someReason);

        (
            bool isOpen,
            bool isRemoved,
            address openBy,
            uint256 expiryDate,
            uint256 totalVote,
            uint256 voteRequired,
            uint256 requestedTimeChange,
            string memory reason
        ) = vr.getCommunityRemovalData(acc1);

        Assert.equal(isOpen, true, "isOpen is set to true.");
        Assert.equal(openBy, deployAdd, "Correctly set creator address.");
        Assert.greaterThan(
            expiryDate,
            vr.removalTimeFrame() + block.timestamp - 5,
            "ExpiryDate is set correctly in future."
        );
        Assert.equal(
            totalVote,
            0,
            "Total number of vote should be 1 at initial."
        );
        Assert.equal(voteRequired, 1, "Vote required should match.");
        Assert.equal(
            reason,
            someReason,
            "Provided reason should be set correctly"
        );
    }

    function shouldSuccessfullyVoteForRemoval() public {
        vr.voteForCommunityRemoval(acc1);
        (
            bool isOpen,
            bool isRemoved,
            address openBy,
            uint256 expiryDate,
            uint256 totalVote,
            uint256 voteRequired,
            uint256 requestedTimeChange,
            string memory reason
        ) = vr.getCommunityRemovalData(acc1);

        Assert.equal(isOpen, false, "isOpen should set to false.");
        Assert.equal(isRemoved, true, "isRemove should set to true.");
        Assert.equal(totalVote, 1, "Total vote should increase");
        Assert.equal(
            vr.allRemovedSize(),
            1,
            "Update allRemove array with removed community address"
        );
        Assert.equal(
            vr.checkIfRegistered(acc1),
            false,
            "Community should be removed from registration details"
        );
        Assert.equal(
            vr.checkIfTrusted(acc1),
            false,
            "Commuinity shoudl be removed from tusted list."
        );
    }
    
    function shouldAlsoRemoveTotalSupplyBalanceIfAddressHadBalance() public {
        Assert.equal(vr.getTotalSupply(), 50, 'Total supply must be removed correctly.');
    }
}
