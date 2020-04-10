pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../PaymentGateway.sol";

contract PaymentGatewayTest {
    PaymentGateway pg;
    address deployAdd;
    
    address acc1;
   
    function beforeAll() public {
        pg = new PaymentGateway();
        acc1 = TestsAccounts.getAccount(1);
        deployAdd = address(this);
        pg.addCommunity(acc1);
        pg.directlyTrustedByOwner(acc1);
    }

    function successfullyRegisterPaymentGatewayAddress() public {
        pg.registerGateway(acc1);
        Assert.equal(pg.paymentGatewayRegistered(acc1), true, 'Address should be successfully registered');
        Assert.equal(pg.getGetwayListLength(deployAdd), 1, 'Should only increment to one');
        Assert.equal(pg.accessGatewayList(deployAdd, 0), acc1, 'Correctly update the list by registered new address');
    }

 }