//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public class TransactionStatus: Assertable {

    // NOTE: If you change enum values, then you'll need to run DB migration.
    // Adding new ones is OK as long as you don't change old values
    public enum Code: Int {
        /// Draft transaction is allowed to change any data
        case draft = 0
        /// Sigining transaction freezes amount, fees, sender and recipient while still allowing to add signatures
        case signing = 1
        /// Pending transaction is the one submitted to a blockchain. Transaction parameters are immutable.
        /// Pending transaction is allowed to set hash, if it wasn't set before.
        case pending = 2
        /// Transaction is rejected by owner (s) and may not be submitted to blockchain.
        case rejected = 3
        /// Transaction may become failed when it is rejected by blockchain.
        case failed = 4
        /// Transaction is successful when it is processed and added to the blockchain
        case success = 5
    }

    var code: TransactionStatus.Code { return .draft }
    var canChangeParameters: Bool { return false }
    var canChangeBlockchainHash: Bool { return false }
    var canChangeSignatures: Bool { return false }

    static func status(_ code: TransactionStatus.Code) -> TransactionStatus {
        switch code {
        case .draft: return DraftTransactionStatus()
        case .signing: return SigningTransactionStatus()
        case .pending: return PendingTransactionStatus()
        case .rejected: return RejectedTransactionStatus()
        case .failed: return FailedTransactionStatus()
        case .success: return SuccessTransactionStatus()
        }
    }

    func reset(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: reset transaction from \(code)")
    }

    func reject(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: reject transaction from \(code)")
    }

    func succeed(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: succeed transaction from \(code)")
    }

    func fail(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: fail transaction from \(code)")
    }

    func proceed(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: proceed transaction from \(code)")
    }

    func stepBack(_ tx: Transaction) {
        preconditionFailure("Illegal state transition: step back transaction from \(code)")
    }

}

class DraftTransactionStatus: TransactionStatus {

    override var code: TransactionStatus.Code { return .draft }
    override var canChangeParameters: Bool { return true }
    override var canChangeBlockchainHash: Bool { return true }
    override var canChangeSignatures: Bool { return true }

    override func proceed(_ tx: Transaction) {
        try! assertNotNil(tx.sender, Transaction.Error.senderNotSet)
        try! assertNotNil(tx.recipient, Transaction.Error.recipientNotSet)
        try! assertNotNil(tx.amount, Transaction.Error.amountNotSet)
        try! assertNotNil(tx.fee, Transaction.Error.feeNotSet)
        tx.change(status: .signing)
            .timestampUpdated(at: Date())
    }

}

class SigningTransactionStatus: TransactionStatus {

    override var code: TransactionStatus.Code { return .signing }
    override var canChangeBlockchainHash: Bool { return true }
    override var canChangeSignatures: Bool { return true }

    override func proceed(_ tx: Transaction) {
        try! assertNotNil(tx.transactionHash, Transaction.Error.transactionHashNotSet)
        tx.change(status: .pending)
            .timestampSubmitted(at: Date())
            .timestampUpdated(at: Date())
    }

    override func reject(_ tx: Transaction) {
        tx.change(status: .rejected)
            .timestampRejected(at: Date())
            .timestampUpdated(at: Date())
    }

    override func stepBack(_ tx: Transaction) {
        tx.change(status: .draft)
    }

}

class PendingTransactionStatus: TransactionStatus {

    override var code: TransactionStatus.Code { return .pending }
    override func succeed(_ tx: Transaction) {
        tx.change(status: .success)
            .timestampProcessed(at: Date())
            .timestampUpdated(at: Date())
    }

    override func fail(_ tx: Transaction) {
        tx.change(status: .failed)
            .timestampProcessed(at: Date())
            .timestampUpdated(at: Date())
    }

    override func stepBack(_ tx: Transaction) {
        tx.change(status: .signing)
    }

}

class RejectedTransactionStatus: TransactionStatus {

    override var code: TransactionStatus.Code { return .rejected }

    override func reset(_ tx: Transaction) {
        tx.resetParameters()
        tx.change(status: .draft)
    }

}

class FailedTransactionStatus: TransactionStatus {
    override var code: TransactionStatus.Code { return .failed }
}

class SuccessTransactionStatus: TransactionStatus {
    override var code: TransactionStatus.Code { return .success }
}
