pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "./VotingRemoval.sol";

contract CommunityERC20Test {
    VotingRemoval vr;
    address deployAdd;

    address acc0;
    address acc1;
    address acc2;
    // Unix time.
    uint8 dateToTrust = 1;

    function beforeAll() public {
        vr = new VotingRemoval();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        deployAdd = address(this);
        
        // Registered new community and give them trusted status.
        vr.addCommunity(acc0);
        vr.directlyTrustedByOwner(acc0);
    }

    function newCommunitySucessfullyRegisteredAndTrusted() public {
        Assert.equal(vr.checkIfRegistered(acc0), true, 'Community not registered');
        Assert.equal(vr.checkIfTrusted(acc0), true, 'Community not trusted');
    }

    function openProposalToChangeTimeFrame() public {
        // Set total number of community required to open voting to 1 for demostration propose.
        // Original is set to 200;
        vr.changeCommunityNumber(1);
        Assert.equal(vr.getCommunityNumber(), 1, 'Community number needs to set to 1');
        vr.openVoteTimeFrame(3, '0xff');
        Assert.equal(vr.isTimeFrameProposalOpen(), true, 'TimeFrame proposal should be open');
    }


}
