pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../ERC20.sol";

contract ERC20Test {
    ERC20 erc;
    address deployAdd;

    address acc0;
    address acc1;

    function beforeAll() public {
        erc = new ERC20();
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        deployAdd = address(this);
        erc.addCommunity(acc0);
        erc.directlyTrustedByOwner(acc0);

        erc.addCommunity(acc1);
        erc.directlyTrustedByOwner(acc1);
        erc.mint(10);
    }

    function trustedCommunityShouldSuccessfullyMintTheToken() public {
        Assert.equal(erc.getBalance(deployAdd), 10, 'Balance should match.');
        Assert.equal(erc.getTotalSupply(), 10, 'Correctly set totalSupply value.');
    }

    function successfullyTransferToken() public {
        erc.transfer(5, acc0);
        Assert.equal(erc.getBalance(deployAdd), 5, 'Sender balance should be reduced by transfer amount.');
        Assert.equal(erc.getBalance(acc0), 5, 'Receiver balance should be increased by transfer amount.');
    }

    function successfullyDestoryFundWhenTransferToPaymentGateAccounts() public {
        erc.registerGateway(acc1);
        Assert.equal(erc.paymentGatewayRegistered(acc1), true, 'Address should be successfully registered');

        erc.transfer(5, acc1);
        Assert.equal(erc.getBalance(deployAdd), 0, 'Sender balance should be reduced by transfer amount.');
        Assert.equal(erc.getBalance(acc1), 0, 'Payment gateway address should not be able to receiver funds.');
        Assert.equal(erc.getTotalSupply(), 5, 'Total supply must be reduced for payment gateway address.');
    }

}
