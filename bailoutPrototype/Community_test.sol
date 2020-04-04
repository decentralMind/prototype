pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "./Community.sol";


contract CommunityERC20Test {
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
    }
    
    function beforeEach() public {
        cmt.addCommunity(acc0);
        cmt.setTrustedDate(dateToTrust);
    }
    
    function shouldCorrectlySetsOwner() public {
        Assert.equal(cmt.getOwner(), address(this), 'Owner accounts should be deployment account.');
    }
    
    function onwerShouldCorretlyAddCommunity() public {
        Assert.equal(cmt.checkIfRegistered(acc0), true, 'Should return true');
    }
    
    function shouldCorrelySetsCommunityTrustedDateForCommunity() public {
        Assert.equal(cmt.getTrustedDate(), dateToTrust, "Trusted date is not correctly set.");
    }
    
    /// #sender: account-0
    function communityShouldBeTrustedAfterSpecificDate() public {
        cmt.addToTrusted(msg.sender);
        Assert.equal(cmt.checkIfTrusted(msg.sender), true, 'Account should be registered as trusted');
    }
    
    function shouldReturnFalseForNonRegisteredCommunity() public {
        Assert.equal(cmt.checkIfRegistered(acc2), false, 'Should return false');
    }
    
    function shouldRemoveAccountSuccessfullyByOwner() public {
        cmt.directlyRemoveCommunity(acc0);
        Assert.equal(cmt.checkIfRegistered(acc0), false, 'Should return false');
    }
    
 }
