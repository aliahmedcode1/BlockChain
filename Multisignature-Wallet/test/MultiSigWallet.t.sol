
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {

    MultiSigWallet wallet;

    address owner1 = makeAddr("owner1");
    address owner2 = makeAddr("owner2");
    address owner3 = makeAddr("owner3");
    address nonOwner = makeAddr("nonOwner");

    address recipient = makeAddr("recipient");

    address[] owners;

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);

        wallet = new MultiSigWallet(owners, 2);

        vm.deal(address(wallet), 10 ether);
    }

    // =========================
    // Deployment Tests
    // =========================

    function testDeployment() public view {
        assertEq(wallet.requiredApprovals(), 2);
        assertEq(wallet.isOwner(owner1), true);
        assertEq(wallet.isOwner(owner2), true);
        assertEq(wallet.isOwner(owner3), true);
        assertEq(wallet.getTransactionCount(), 0);
    }

    function testCannotDeployWithZeroApprovals() public {
        vm.expectRevert("Invalid approval requirement");

        new MultiSigWallet(owners, 0);
    }

    function testCannotDeployWithDuplicateOwners() public {
        address[] memory duplicateOwners = new address[](2);

        duplicateOwners[0] = owner1;
        duplicateOwners[1] = owner1;

        vm.expectRevert("Duplicate owner");

        new MultiSigWallet(duplicateOwners, 1);
    }

    // =========================
    // Submit Tests
    // =========================

    function testSubmitTransaction() public {
        vm.prank(owner1);

        wallet.submitTransaction(
            recipient,
            1 ether,
            ""
        );

        assertEq(wallet.getTransactionCount(), 1);
    }

    function testNonOwnerCannotSubmit() public {
        vm.prank(nonOwner);

        vm.expectRevert("Not an owner");

        wallet.submitTransaction(recipient, 1 ether, "");
    }

    // =========================
    // Confirmation Tests
    // =========================

    function testConfirmTransaction() public {
        _submitTransaction();

        vm.prank(owner1);
        wallet.confirmTransaction(0);

        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(0);

        assertEq(transaction.approvalCount, 1);
    }

    function testCannotConfirmTwice() public {
        _submitTransaction();

        vm.startPrank(owner1);

        wallet.confirmTransaction(0);

        vm.expectRevert("Already approved");
        wallet.confirmTransaction(0);

        vm.stopPrank();
    }

    function testNonOwnerCannotConfirm() public {
        _submitTransaction();

        vm.prank(nonOwner);

        vm.expectRevert("Not an owner");

        wallet.confirmTransaction(0);
    }

    // =========================
    // Revoke Tests
    // =========================

    function testRevokeConfirmation() public {
        _submitTransaction();

        vm.startPrank(owner1);

        wallet.confirmTransaction(0);
        wallet.revokeConfirmation(0);

        vm.stopPrank();

        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(0);

        assertEq(transaction.approvalCount, 0);
    }

    // =========================
    // Execution Tests
    // =========================

    function testCannotExecuteWithoutEnoughApprovals() public {
        _submitTransaction();

        vm.prank(owner1);
        wallet.confirmTransaction(0);

        vm.prank(owner1);

        vm.expectRevert("Not enough approvals");

        wallet.executeTransaction(0);
    }

    function testExecuteTransaction() public {
        _submitTransaction();

        vm.prank(owner1);
        wallet.confirmTransaction(0);

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        uint256 balanceBefore = recipient.balance;

        vm.prank(owner3);
        wallet.executeTransaction(0);

        assertEq(recipient.balance, balanceBefore + 1 ether);

        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(0);

        assertTrue(transaction.executed);
    }

    function testCannotExecuteTwice() public {
        _submitTransaction();

        vm.prank(owner1);
        wallet.confirmTransaction(0);

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        vm.prank(owner1);
        wallet.executeTransaction(0);

        vm.prank(owner2);

        vm.expectRevert("Already executed");

        wallet.executeTransaction(0);
    }

    // =========================
    // Helper Function
    // =========================

    function _submitTransaction() internal {
        vm.prank(owner1);

        wallet.submitTransaction(
            recipient,
            1 ether,
            ""
        );
    }
}
