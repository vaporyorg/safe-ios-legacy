//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import MultisigWalletApplication

final class NewSafeFlowCoordinator: FlowCoordinator {

    var paperWalletFlowCoordinator = PaperWalletFlowCoordinator()

    var isSafeCreationInProgress: Bool {
        return ApplicationServiceRegistry.walletService.isSafeCreationInProgress
    }

    override func setUp() {
        super.setUp()
        if ApplicationServiceRegistry.walletService.hasReadyToUseWallet {
            exitFlow()
            return
        }
        push(NewSafeViewController.create(delegate: self))
        saveCheckpoint()
        if ApplicationServiceRegistry.walletService.hasPendingWalletCreation {
            push(PendingSafeViewController.create(delegate: self))
        }
    }

}

extension NewSafeFlowCoordinator {

    func enterAndComeBack(from coordinator: FlowCoordinator) {
        saveCheckpoint()
        enter(flow: coordinator) {
            self.popToLastCheckpoint()
        }
    }

}

extension NewSafeFlowCoordinator: NewSafeDelegate {

    func didSelectPaperWalletSetup() {
        enterAndComeBack(from: paperWalletFlowCoordinator)
    }

    func didSelectBrowserExtensionSetup() {
        push(PairWithBrowserExtensionViewController.create(delegate: self))
    }

    func didSelectNext() {
        push(PendingSafeViewController.create(delegate: self))
    }

}

extension NewSafeFlowCoordinator: PairWithBrowserDelegate {

    func didPair() {
        pop()
    }

}

extension NewSafeFlowCoordinator: PendingSafeViewControllerDelegate {

    func deploymentDidFail() {
        let controller = SafeCreationFailedAlertController.create { [unowned self] in
            self.dismissModal()
            self.popToLastCheckpoint()
        }
        presentModally(controller)
    }

    func deploymentDidSuccess() {
        exitFlow()
    }

    func deploymentDidCancel() {
        let controller = AbortSafeCreationAlertController.create(abort: { [unowned self] in
            self.dismissModal()
            self.popToLastCheckpoint()
        }, continue: { [unowned self] in
            self.dismissModal()
        })
        presentModally(controller)
    }

}