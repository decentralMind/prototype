pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../VotingRemoval.sol";


contract InitalTest {
    VotingRemoval vr;
    address deployAdd;

    address acc0;
    address acc1;

    function beforeAll() public {
        vr = new VotingRemoval();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        deployAdd = address(this);

        vr.changeCommunityNumber(1);

        vr.addCommunity(acc0);
        vr.directlyTrustedByOwner(acc0);

        vr.addCommunity(acc1);
        vr.directlyTrustedByOwner(acc1);
    }

    function beforeEachShouldSuccessfullySetCommunityNumber() public {
        Assert.equal(
            vr.getCommunityNumber(),
            1,
            "Community number needs to set to 1"
        );
    }

    function newCommunitySucessfullyRegisteredAndTrusted() public {
        Assert.equal(
            vr.checkIfRegistered(acc0),
            true,
            "acc0 should be registered"
        );
        Assert.equal(
            vr.checkIfTrusted(acc0),
            true,
            "acc0 should be listed as trusted"
        );

        Assert.equal(
            vr.checkIfRegistered(acc1),
            true,
            "acc1 should be registered"
        );
        Assert.equal(
            vr.checkIfTrusted(acc1),
            true,
            "acc1 should be listed as trusted"
        );
    }
    
}
