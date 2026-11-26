
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    // =========================
    // State Variables
    // =========================

    address[] public owners;
    uint256 public requiredApprovals;

    mapping(address => bool) public isOwner;

    // =========================
    // Transaction Structure
    // =========================

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    Transaction[] public transactions;

    // transactionId => owner => approved?
    mapping(uint256 => mapping(address => bool)) public approved;

    // =========================
    // Events
    // =========================

    event TransactionSubmitted(
        uint256 indexed transactionId,
        address indexed submitter,
        address indexed to,
        uint256 value
    );

    event TransactionConfirmed(
        uint256 indexed transactionId,
        address indexed owner
    );

    event ConfirmationRevoked(
        uint256 indexed transactionId,
        address indexed owner
    );

    event TransactionExecuted(
        uint256 indexed transactionId
    );

    // =========================
    // Modifiers
    // =========================

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactionId < transactions.length,
            "Transaction does not exist"
        );
        _;
    }

    // =========================
    // Constructor
    // =========================

    constructor(
        address[] memory _owners,
        uint256 _requiredApprovals
    ) {
        require(_owners.length > 0, "Owners required");

        require(
            _requiredApprovals > 0 &&
            _requiredApprovals <= _owners.length,
            "Invalid approval requirement"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // =========================
    // Receive ETH
    // =========================

    receive() external payable {}

    // =========================
    // Submit Transaction
    // =========================

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        require(to != address(0), "Invalid destination");

        uint256 transactionId = transactions.length;

        transactions.push(
            Transaction({
                to: to,
                value: value,
                data: data,
                executed: false,
                approvalCount: 0
            })
        );

        emit TransactionSubmitted(
            transactionId,
            msg.sender,
            to,
            value
        );
    }

    // =========================
    // Confirm Transaction
    // =========================

    function confirmTransaction(
        uint256 transactionId
    )
        external
        onlyOwner
        transactionExists(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];

        require(!transaction.executed, "Already executed");
        require(!approved[transactionId][msg.sender], "Already approved");

        approved[transactionId][msg.sender] = true;
        transaction.approvalCount++;

        emit TransactionConfirmed(transactionId, msg.sender);
    }

    // =========================
    // Revoke Confirmation
    // =========================

    function revokeConfirmation(
        uint256 transactionId
    )
        external
        onlyOwner
        transactionExists(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];

        require(!transaction.executed, "Already executed");
        require(approved[transactionId][msg.sender], "Not approved");

        approved[transactionId][msg.sender] = false;
        transaction.approvalCount--;

        emit ConfirmationRevoked(transactionId, msg.sender);
    }

    // =========================
    // Execute Transaction
    // =========================

    function executeTransaction(
        uint256 transactionId
    )
        external
        onlyOwner
        transactionExists(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];

        require(!transaction.executed, "Already executed");

        require(
            transaction.approvalCount >= requiredApprovals,
            "Not enough approvals"
        );

        // Effects before external call
        transaction.executed = true;

        (bool success, ) = transaction.to.call{
            value: transaction.value
        }(transaction.data);

        require(success, "Transaction failed");

        emit TransactionExecuted(transactionId);
    }

    // =========================
    // View Functions
    // =========================

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(
        uint256 transactionId
    )
        external
        view
        transactionExists(transactionId)
        returns (Transaction memory)
    {
        return transactions[transactionId];
    }
}
