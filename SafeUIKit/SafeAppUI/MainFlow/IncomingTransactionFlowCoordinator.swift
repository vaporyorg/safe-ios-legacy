//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication

class IncomingTransactionFlowCoordinator: FlowCoordinator {

    let transactionID: String
    private let source: TransactionSource
    private let sourceMeta: Any?
    private let onBackButton: (() -> Void)?

    enum TransactionSource {
        case browserExtension
        case walletConnect
    }

    init(transactionID: String, source: TransactionSource, sourceMeta: Any?, onBackButton: (() -> Void)?) {
        self.transactionID = transactionID
        self.source = source
        self.sourceMeta = sourceMeta
        self.onBackButton = onBackButton
    }

    override func setUp() {
        super.setUp()
        switch source {
        case .browserExtension:
            let reviewVC = SendReviewViewController(transactionID: transactionID, delegate: self)
            reviewVC.onBack = { [weak self] in
                self?.onBackButton?()
            }
            push(reviewVC)
        case .walletConnect:
            let wcSessionData = sourceMeta as! WCSessionData
            let reviewVC = WCSendReviewViewController(transactionID: transactionID, delegate: self)
            reviewVC.wcSessionData = wcSessionData
            reviewVC.onBack = { [weak self] in
                guard let `self` = self else { return }
                self.onBackButton?()
                self.pop()
                self.showCompletion()
            }
            push(reviewVC)
        }
    }

    private var didComeViaWalletConnect: Bool {
        source == .walletConnect && sourceMeta is WCSessionData
    }

    private func showCompletion() {
        guard didComeViaWalletConnect else { return }
        let vc = WCCompletionPanelViewController.create()
        vc.present(from: rootViewController)
    }

}

extension IncomingTransactionFlowCoordinator: ReviewTransactionViewControllerDelegate {

    public func reviewTransactionViewControllerWantsToSubmitTransaction(_ controller: ReviewTransactionViewController,
                                                                        completion: @escaping (Bool) -> Void) {
        TransactionSubmissionHandler().submitTransaction(from: self, completion: completion)
    }

    public func reviewTransactionViewControllerDidFinishReview(_ controller: ReviewTransactionViewController) {
        if didComeViaWalletConnect {
            showCompletion()
            exitFlow()
            return
        }
        push(SuccessViewController.sendSuccess(token: controller.tx.amountTokenData) { [weak self] in
            self?.exitFlow()
        })
    }

}
