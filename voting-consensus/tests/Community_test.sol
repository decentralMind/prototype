pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../main/Community.sol";


contract CommunityTest {
    Community cmt;
    address deployAdd;

    address acc0;
    address acc1;
    address acc2;
    // Unix time.
    uint8 dateToTrust = 1;

    function beforeAll() public {
        cmt = new Community();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        deployAdd = address(this);
        cmt.addCommunity(acc0);
    }

    function shouldCorrectlySetsOwner() public {
        Assert.equal(
            cmt.getOwner(),
            address(this),
            "Owner accounts should be deployment account."
        );
    }

    function onwerShouldCorretlyAddCommunity() public {
        Assert.equal(cmt.checkIfRegistered(acc0), true, "Should return true");
    }

    function shouldNotRegisterSameCommunityTwice() public {
        bytes memory payload = abi.encodeWithSignature(
            "addCommunity(address)",
            acc0
        );

        (bool success, ) = address(cmt).call(payload);

        Assert.equal(
            success,
            false,
            "Should revert if trying register same community twice"
        );
    }

    function shouldCorrelySetsCommunityTrustedDateForCommunity() public {
        cmt.setTrustedDate(1);
        Assert.equal(
            cmt.getTrustedDate(),
            1,
            "Trusted date is not correctly set."
        );
    }

    function comminitiesShouldBeAbleToSetToTrusted() public {
        cmt.directlyTrustedByOwner(acc0);
        Assert.equal(
            cmt.checkIfTrusted(acc0),
            true,
            "Commuity should be set as trusted."
        );
        Assert.equal(
            cmt.numberOfTrustedCommunities(),
            1,
            "Trusted Community should increase"
        );
    }

    function shouldReturnFalseForNonRegisteredCommunity() public {
        Assert.equal(cmt.checkIfRegistered(acc2), false, "Should return false");
    }

    function shouldRemoveAccountSuccessfullyByOwner() public {
        cmt.directlyRemoveCommunity(acc0);
        Assert.equal(cmt.checkIfRegistered(acc0), false, "Should return false");
    }
}
