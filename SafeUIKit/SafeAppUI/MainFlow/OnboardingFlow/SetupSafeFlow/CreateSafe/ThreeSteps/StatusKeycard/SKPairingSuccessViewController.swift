//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import MultisigWalletApplication

class SKPairingSuccessViewController: HeaderImageTextStepController {

    var backButtonItem: UIBarButtonItem!
    var shouldRemoveOnBack: Bool = true

    private var onRemove: (() -> Void)!

    enum Strings {
        static let header = LocalizedString("keycard_paired", comment: "Paired")
        static let text = LocalizedString("after_finishing_setup", comment: "Description")
    }

    static func create(onNext: @escaping () -> Void, onRemove: @escaping () -> Void) -> SKPairingSuccessViewController {
        let controller = SKPairingSuccessViewController(nibName: String(describing: CardViewController.self),
                                                        bundle: Bundle(for: CardViewController.self))
        controller.onNext = onNext
        controller.onRemove = onRemove
        controller.backButtonItem = UIBarButtonItem.backButton(target: controller, action: #selector(back))
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        trackingEvent = TwoFATrackingEvent.pairSuccess
        threeStepsView.state = .pair2FA_paired
        headerImageTextView.titleLabel.text = Strings.header
        headerImageTextView.imageView.image = Asset.statusKeycardPaired.image
        headerImageTextView.textLabel.attributedText = NSAttributedString(string: Strings.text,
                                                                          style: DescriptionStyle())
    }

    override func willMove(toParent parent: UIViewController?) {
        setCustomBackButton(backButtonItem)
    }

    @objc func back() {
        guard shouldRemoveOnBack else {
            return
        }
        let title = LocalizedString("remove_paired", comment: "Remove?")
        let message = LocalizedString("paired_will_be_lost", comment: "You'll remove")
        let remove = LocalizedString("remove", comment: "Remove")

        let alert = UIAlertController.create(title: title, message: message)
            .withCloseAction()
            .withDestructiveAction(title: remove) { [unowned self] in
                ApplicationServiceRegistry.keycardService.removeKeycard()
                self.onRemove()
        }
        present(alert, animated: true)
    }

}

extension SKPairingSuccessViewController: InteractivePopGestureResponder {

    func interactivePopGestureShouldBegin() -> Bool {
        return false
    }

}
