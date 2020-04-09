pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "./VotingRemoval.sol";

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
    
    
    
}
