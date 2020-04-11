pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../main/CommunityRemoval.sol";


contract CommunityTest {
    CommunityRemoval cr;
    address deployAdd;

    address acc0;
    address acc1;
    address acc2;
    // Unix time.
    uint8 dateToTrust = 1;

    function beforeAll() public {
        cr = new CommunityRemoval();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        deployAdd = address(this);
        cr.addCommunity(acc0);
        cr.directlyTrustedByOwner(acc0);

        // Mint and transfer token for testing propose.
        cr.mint(100);
        cr.transfer(50, acc0);
    }

    function shouldLoadWithCorrectBalance() public {
        Assert.equal(cr.balanceOf(acc0), 50, "Balance Should load correctly.");
        Assert.equal(cr.getTotalSupply(), 100, "Correctly loads total supply.");
    }

    function shouldDirectlyRemoveCommunityByOwner() public {
        cr.directlyRemoveCommunity(acc0);

        Assert.equal(
            cr.checkIfRegistered(acc0),
            false,
            "Account should not belabel as registered."
        );
        Assert.equal(
            cr.checkIfTrusted(acc0),
            false,
            "Account should not be label as trusetd."
        );

        Assert.equal(
            cr.getTotalSupply(),
            50,
            "Total supply should reduced if removed account had balance in it."
        );
    }
}
