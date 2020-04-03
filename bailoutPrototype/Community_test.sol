pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "./Community.sol";

contract CommunityERC20Test {
    Community comm;

    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    
    function beforeAll() public {
        comm = new Community();
        acc1 = TestsAccounts.getAccount(0);
        acc2 = TestsAccounts.getAccount(1);
        acc3 = TestsAccounts.getAccount(2);
        // acc4 = TestsAccounts.getAccount(3);
        // acc5 = TestsAccounts.getAccount(4);
    }
    
    function checkCorrectAccountsLoaded() public {
        Assert.equal(acc1, TestsAccounts.getAccount(0), 'Account should be getAccount(0)');
        Assert.equal(acc2, TestsAccounts.getAccount(1), 'Account should be getAccount(1)');
        Assert.equal(acc3, TestsAccounts.getAccount(2), 'Account should be getAccount(2)');
    }
    
    funciton corretlySetsOwner() public {
        
    }
    
}