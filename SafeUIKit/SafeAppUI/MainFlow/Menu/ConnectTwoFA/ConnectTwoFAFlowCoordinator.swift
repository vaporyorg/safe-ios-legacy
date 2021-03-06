//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication

class ConnectTwoFAFlowCoordinator: FlowCoordinator {

    weak var intro: RBEIntroViewController!
    var transactionID: RBETransactionID!
    var transactionSubmissionHandler = TransactionSubmissionHandler()
    var keycardFlowCoordinator = SKKeycardFlowCoordinator()

    enum Strings {
        static let enableTwoFA = LocalizedString("connect_2fa", comment: "Pair 2FA device")
        static let pairDescription = LocalizedString("pair_2FA_device_description",
                                                     comment: "Pair 2FA device description")
        static let pairReviewDescription = LocalizedString("pair_2fa_review_description",
                                                           comment: "Pair 2FA review description")
        static let statusKeyacard = LocalizedString("status_keycard", comment: "Status Keycard")
        static let gnosisSafeAuthenticator = LocalizedString("gnosis_safe_authenticator",
                                                             comment: "Gnosis Safe Authenticator")
    }

    override func setUp() {
        super.setUp()
        let vc = introViewController()
        push(vc)
        intro = vc
    }

}

extension IntroContentView.Content {

    static let pairTwoFAContent =
        IntroContentView
            .Content(body: ConnectTwoFAFlowCoordinator.Strings.pairDescription,
                     icon: Asset.setup2FA.image)

}

/// Screens factory methods
extension ConnectTwoFAFlowCoordinator {

    func introViewController() -> RBEIntroViewController {
        let vc = RBEIntroViewController.create()
        vc.starter = ApplicationServiceRegistry.connectTwoFAService
        vc.delegate = self
        vc.setTitle(Strings.enableTwoFA)
        vc.setContent(.pairTwoFAContent)
        vc.screenTrackingEvent = ConnectTwoFATrackingEvent.intro
        return vc
    }

    func pairWithTwoFA() -> TwoFATableViewController {
        let controller = TwoFATableViewController()
        controller.delegate = self
        return controller
    }

    func connectAuthenticatorViewController() -> AuthenticatorViewController {
        return AuthenticatorViewController.createRBEConnectController(delegate: self)
    }

    func reviewConnectAuthenticatorViewController() -> RBEReviewTransactionViewController {
        return reviewTransactionVC(placeholderValue: Strings.gnosisSafeAuthenticator)
    }

    func reviewConnectKeycardViewController() -> RBEReviewTransactionViewController {
        return reviewTransactionVC(placeholderValue: Strings.statusKeyacard)
    }

    private func reviewTransactionVC(placeholderValue: String) -> RBEReviewTransactionViewController {
        let vc = RBEReviewTransactionViewController(transactionID: transactionID, delegate: self)
        vc.titleString = Strings.enableTwoFA
        vc.detailString = String(format: Strings.pairReviewDescription, placeholderValue)
        vc.screenTrackingEvent = ConnectTwoFATrackingEvent.review
        vc.successTrackingEvent = ConnectTwoFATrackingEvent.success
        return vc
    }

}

extension ConnectTwoFAFlowCoordinator: RBEIntroViewControllerDelegate {

    func rbeIntroViewControllerDidStart() {
        transactionID = intro.transactionID
        push(pairWithTwoFA())
    }

}

extension ConnectTwoFAFlowCoordinator: TwoFATableViewControllerDelegate {

    func didSelectTwoFAOption(_ option: TwoFAOption) {
        switch option {
        case .statusKeycard:
            ApplicationServiceRegistry.connectTwoFAService.updateTransaction(transactionID, with: .connectStatusKeycard)
            keycardFlowCoordinator.hidesSteps = true
            keycardFlowCoordinator.removesKeycardOnGoingBack = false
            keycardFlowCoordinator.flowTitle = Strings.enableTwoFA
            let transactionID = self.transactionID!
            keycardFlowCoordinator.onSucces = { address in
                try ApplicationServiceRegistry.connectTwoFAService.connectKeycard(transactionID, address: address)
            }
            enter(flow: keycardFlowCoordinator) { [unowned self] in
                self.push(self.reviewConnectKeycardViewController())
            }
        case .gnosisAuthenticator:
            ApplicationServiceRegistry.connectTwoFAService.updateTransaction(transactionID, with: .connectAuthenticator)
            push(connectAuthenticatorViewController())
        }
    }

    func didSelectLearnMore(for option: TwoFAOption) {
        let supportCoordinator = SupportFlowCoordinator(from: self)
        switch option {
        case .gnosisAuthenticator:
            supportCoordinator.openAuthenticatorInfo()
        case .statusKeycard:
            supportCoordinator.openStausKeycardInfo()
        }
    }

}

extension ConnectTwoFAFlowCoordinator: AuthenticatorViewControllerDelegate {

    func authenticatorViewController(_ controller: AuthenticatorViewController,
                                     didScanAddress address: String,
                                     code: String) throws {
        try ApplicationServiceRegistry.connectTwoFAService.connect(transaction: transactionID, code: code)
    }

    func authenticatorViewControllerDidFinish() {
        push(reviewConnectAuthenticatorViewController())
    }

    func didSelectOpenAuthenticatorInfo() {
        SupportFlowCoordinator(from: self).openAuthenticatorInfo()
    }

}

extension ConnectTwoFAFlowCoordinator: ReviewTransactionViewControllerDelegate {

    func reviewTransactionViewControllerWantsToSubmitTransaction(_ controller: ReviewTransactionViewController,
                                                                 completion: @escaping (Bool) -> Void) {
        transactionSubmissionHandler.submitTransaction(from: self, completion: completion)
    }

    func reviewTransactionViewControllerDidFinishReview(_ controller: ReviewTransactionViewController) {
        let txID = self.transactionID!
        DispatchQueue.global.async {
            ApplicationServiceRegistry.connectTwoFAService.startMonitoring(transaction: txID)
        }
        push(SuccessViewController.connect2FASuccess { [weak self] in
            self?.exitFlow()
        })
    }

}

extension SuccessViewController {

    static func connect2FASuccess(action: @escaping () -> Void) -> SuccessViewController {
        return .congratulations(text: LocalizedString("connecting_in_progress", comment: "Explanation text"),
                                image: Asset.setup2FA.image,
                                tracking: ConnectTwoFATrackingEvent.success,
                                action: action)
    }

}
