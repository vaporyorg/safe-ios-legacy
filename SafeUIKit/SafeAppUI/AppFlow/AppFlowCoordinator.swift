//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import UIKit
import IdentityAccessApplication
import MultisigWalletApplication

open class AppFlowCoordinator: FlowCoordinator {

    let onboardingFlowCoordinator = OnboardingFlowCoordinator()
    private var lockedViewController: UIViewController!

    private var authenticationService: AuthenticationApplicationService {
        return IdentityAccessApplication.ApplicationServiceRegistry.authenticationService
    }
    private var walletService: WalletApplicationService {
        return MultisigWalletApplication.ApplicationServiceRegistry.walletService
    }
    private var applicationRootViewController: UIViewController? {
        get { return UIApplication.shared.keyWindow?.rootViewController }
        set { UIApplication.shared.keyWindow?.rootViewController = newValue }
    }

    private var shouldLockWhenAppActive: Bool {
        return authenticationService.isUserRegistered  && !authenticationService.isUserAuthenticated
    }

    public init() {
        super.init(rootViewController: TransparentNavigationController())
    }

    // TODO: transform to setUp()
    open func startViewController() -> UIViewController {
        if walletService.hasReadyToUseWallet {
            lockedViewController = mainController()
        } else {
            enter(flow: onboardingFlowCoordinator)
            lockedViewController = rootViewController
        }

        if authenticationService.isUserRegistered {
            return unlockController { [unowned self] in
                self.applicationRootViewController = self.lockedViewController
            }
        }
        return lockedViewController
    }

    private func mainController() -> UIViewController {
        return MainViewController.create()
    }

    func unlockController(completion: @escaping () -> Void) -> UIViewController {
        return UnlockViewController.create(completion: completion)
    }

    open func appEntersForeground() {
        guard let rootVC = self.applicationRootViewController,
            !(rootVC is UnlockViewController) && shouldLockWhenAppActive else {
            return
        }
        lockedViewController = rootVC
        self.applicationRootViewController = unlockController { [unowned self] in
            self.applicationRootViewController = self.lockedViewController
        }
    }

}
