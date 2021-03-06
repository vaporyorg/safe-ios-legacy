//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

extension RBEIntroViewController {

    class LoadingState: CancellableState {

        override func didEnter(controller: RBEIntroViewController) {
            controller.startIndicateLoading()
            controller.showStart()
            controller.disableStart()
            controller.feeCalculation = OwnerModificationFeeCalculation()
            reload(controller: controller)
        }

        private func reload(controller: RBEIntroViewController) {
            asyncInBackground {
                guard let transactionID = controller.transactionID ?? controller.starter?.create(),
                    let updatedTransactionId = controller.starter?
                        .recreateTransactionIfPaymentMethodChanged(transaction: transactionID) else { return }
                controller.transactionID = updatedTransactionId
                guard let estimation = controller.starter?.estimate(transaction: updatedTransactionId) else { return }
                DispatchQueue.main.sync {
                    controller.calculationData = estimation.feeCalculation
                    if let error = estimation.error {
                        controller.handleError(error)
                    } else {
                        controller.didLoad()
                    }
                }
            }
        }

        override func willPush(controller: RBEIntroViewController, onTopOf topViewController: UIViewController) {
            topViewController.navigationItem.backBarButtonItem = controller.backButtonItem
        }

        override func handleError(_ error: Error, controller: RBEIntroViewController) {
            controller.transition(to: InvalidState(error: error))
        }

        override func didLoad(controller: RBEIntroViewController) {
            controller.transition(to: ReadyState())
        }

    }

}
