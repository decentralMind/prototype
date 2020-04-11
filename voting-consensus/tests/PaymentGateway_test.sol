pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../main/PaymentGateway.sol";


contract PaymentGatewayTest {
    PaymentGateway pg;
    address deployAdd;
    address acc1;
    address acc2;

    function beforeAll() public {
        pg = new PaymentGateway();
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        deployAdd = address(this);
        pg.addCommunity(acc1);
        pg.directlyTrustedByOwner(acc1);
    }

    function successfullyRegisterPaymentGatewayAddress() public {
        pg.registerGateway(acc2);
        Assert.equal(
            pg.paymentGatewayRegistered(acc2),
            true,
            "Address should be successfully registered"
        );
    }

    function shouldFailIfRegisteredCommunityAdddressIsProvided() public {
        bytes memory payload = abi.encodeWithSignature(
            "registerGateway(address)",
            acc1
        );
        (bool success, ) = address(pg).call(payload);

        Assert.equal(
            success,
            false,
            "Should return false if the address is registered as community"
        );
    }

    function shouldFailAddressAlreadyRegisteredAsPaymentGateway() public {
        bytes memory payload = abi.encodeWithSignature(
            "registerGateway(address)",
            acc2
        );
        (bool success, ) = address(pg).call(payload);

        Assert.equal(
            success,
            false,
            "Should return false if the address is address is already registered as payment gateway"
        );
    }
}
