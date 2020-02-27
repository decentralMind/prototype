pragma solidity ^0.5.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "./CommunityERC20.sol";

contract CommunityERC20Test {
    CommunityERC20 cerc;

    address acc1;
    address acc2;
    address acc3;
    address mainAcc;

    uint256 mainAccIndex;
    uint256 currentBatch;
    uint256[2] lastArray;
    bytes payload;

    function beforeAll() public {
        cerc = new CommunityERC20();
        acc1 = TestsAccounts.getAccount(0);
        acc2 = TestsAccounts.getAccount(1);
        acc3 = TestsAccounts.getAccount(2);
        mainAcc = address(this);
    }

    function successfulRegistrationOfNewCommunity() public {
        cerc.addCommunity(acc1);
        Assert.equal(
            cerc.findCommunityIndex(acc1),
            1,
            "initial index should be 1"
        );
        Assert.equal(
            acc1,
            cerc.getAddressFromIndex(1),
            "address should be account 1"
        );
        Assert.equal(
            cerc.getTotalCommunity(),
            1,
            "Total community registered should be 1"
        );
    }

    function successfulRegistrationOfMultipleCommunities() public {
        cerc.addCommunity(acc2);
        cerc.addCommunity(acc3);
        Assert.equal(
            cerc.findCommunityIndex(acc2),
            2,
            "initial index should be 2"
        );
        Assert.equal(
            cerc.findCommunityIndex(acc3),
            3,
            "initial index should be 3"
        );
        Assert.equal(
            acc2,
            cerc.getAddressFromIndex(2),
            "address should be account 2"
        );
        Assert.equal(
            acc3,
            cerc.getAddressFromIndex(3),
            "address should be account 3"
        );
        Assert.equal(
            cerc.getTotalCommunity(),
            3,
            "Total community registered should be 3"
        );
    }

    function communityCannotRegisterTwiceWithSameAddress() public {
        payload = abi.encodeWithSignature("addCommunity(address)", acc1);
        (bool success, bytes memory returnData) = address(cerc).call(payload);
        Assert.equal(
            success,
            false,
            "Should not be able to register with same address twice"
        );
    }

    function successfullyMintToken() public {
        cerc.addCommunity(address(this));
        cerc.mint(address(this), 100);
        Assert.equal(
            cerc.getTotalBalance(address(this)),
            100,
            "Should be 100 token"
        );
    }

    function shouldOnlyMintTokenOnceForCurrentBatch() public {
        payload = abi.encodeWithSignature(
            "mint(address,uint256)",
            mainAcc,
            100
        );
        (bool success, bytes memory returnData) = address(cerc).call(payload);
        Assert.equal(
            success,
            false,
            "Should disallow to mint token more than once for same batch"
        );
    }

    function successfullyUpdateMinterBalanceAfterMint() public {
        mainAccIndex = cerc.findCommunityIndex(mainAcc);
        currentBatch = cerc.getCurrentBatch();
        lastArray = cerc.getLastArrayIndex(mainAcc);

        Assert.equal(
            cerc.getBalanceLength(mainAcc),
            1,
            "Balance array length should be 1"
        );
        Assert.equal(
            keccak256(abi.encodePacked(lastArray)),
            keccak256(abi.encodePacked([mainAccIndex, currentBatch])),
            "Balance array not correct"
        );
    }

    function successfulTransferTest() public {
        cerc.transfer(acc2, 10);
        mainAccIndex = cerc.findCommunityIndex(mainAcc);
        currentBatch = cerc.getCurrentBatch();
        lastArray = cerc.getLastArrayIndex(acc2);

        Assert.equal(
            cerc.getTotalBalance(acc2),
            10,
            "Total balance should be 10"
        );
        Assert.equal(
            cerc.getBalanceLength(acc2),
            1,
            "Balance length should be 1"
        );
        Assert.equal(
            keccak256(abi.encodePacked(lastArray)),
            keccak256(abi.encodePacked([mainAccIndex, currentBatch])),
            "Balance array not correct"
        );
    }

    function batchNumberShouldIncrease() public {
        cerc.increaseBatchNumber();
        Assert.equal(
            cerc.getCurrentBatch(),
            2,
            "Batch number should increase to 2"
        );
    }

    function successfullyShouldMintTokenAfterBatchUpdate() public {
        cerc.mint(mainAcc, 10);
        Assert.equal(
            cerc.getTotalBalance(address(this)),
            100,
            "Should be 100 token"
        );
    }

    function upadeBalanceArraySuccessfullyAfterBatchUpdateMint() public {
        Assert.equal(
            cerc.getBalanceLength(mainAcc),
            2,
            "Balance array length should be 2"
        );
        mainAccIndex = cerc.findCommunityIndex(mainAcc);
        currentBatch = cerc.getCurrentBatch();
        lastArray = cerc.getLastArrayIndex(mainAcc);
        Assert.equal(
            keccak256(abi.encodePacked(lastArray)),
            keccak256(abi.encodePacked([mainAccIndex, currentBatch])),
            "Balance array not correct"
        );

    }

    function shouldPropertlyUpdateBalanceArrayAfterTransfer() public {
        cerc.transfer(acc2, 10);
        mainAccIndex = cerc.findCommunityIndex(mainAcc);
        currentBatch = cerc.getCurrentBatch();
        lastArray = cerc.getLastArrayIndex(acc2);

        Assert.equal(
            cerc.getTotalBalance(acc2),
            20,
            "Total balance should be 10"
        );
        Assert.equal(
            cerc.getBalanceLength(acc2),
            2,
            "Balance length should be 1"
        );
        Assert.equal(
            keccak256(abi.encodePacked(lastArray)),
            keccak256(abi.encodePacked([mainAccIndex, currentBatch])),
            "Balance array not correct"
        );
    }

}
