pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../VotingRemoval.sol";


contract CalculateVoteRequiredTest {
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
     
    function consensusCalcuationShouldBeCorrect() public {
       Assert.equal(vr.calculateVotingRequired(), 2, 'Should return 2.');
    }
    
    function consensusCalcuationShouldBeCorrectMultiple() public {
        // Register 4 communities with full label as trusted for testing purposes.
        vr.addCommunity(TestsAccounts.getAccount(2));
        vr.directlyTrustedByOwner(TestsAccounts.getAccount(2));
        
        vr.addCommunity(deployAdd);
        vr.directlyTrustedByOwner(deployAdd);
        
        Assert.equal(vr.calculateVotingRequired(), 3, 'Should return 3.');
    }
    
}
