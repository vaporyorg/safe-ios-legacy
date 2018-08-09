//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import CommonTestSupport
import MultisigWalletApplication

class MainFlowCoordinatorTests: SafeTestCase {

    var mainFlowCoordinator: MainFlowCoordinator!

    override func setUp() {
        super.setUp()
        mainFlowCoordinator = MainFlowCoordinator(rootViewController: UINavigationController())
    }

    func test_whenSetupCalled_thenShowsMainScreen() {
        mainFlowCoordinator.setUp()
        XCTAssertTrue(mainFlowCoordinator.navigationController.topViewController is MainViewController)
    }

    func test_whenMainViewDidAppeatCalled_thenAuthWithPushTokenCalled() {
        mainFlowCoordinator.mainViewDidAppear()
        XCTAssertNotNil(walletService.authCalled)
    }

    func test_whenCreatingNewTransaction_thenOpensFundsTransferVC() {
        mainFlowCoordinator.setUp()
        mainFlowCoordinator.createNewTransaction()
        delay()
        XCTAssertTrue(mainFlowCoordinator.navigationController.topViewController
            is FundsTransferTransactionViewController)
    }

    func test_whenDraftTransactionCreated_thenOpensTransactionReviewVC() {
        mainFlowCoordinator.setUp()
        mainFlowCoordinator.didCreateDraftTransaction(id: "some")
        delay()
        let vc = mainFlowCoordinator.navigationController.topViewController as? TransactionReviewViewController
        XCTAssertNotNil(vc)
        XCTAssertEqual(vc?.transactionID, "some")
    }

    func test_whenReceivingRemoteMessageData_thenPassesItToService() {
        mainFlowCoordinator.receive(message: ["key": "value"])
        XCTAssertEqual(walletService.receive_input?["key"] as? String, "value")
    }

    func test_whenReceivingRemoteMessageAndReviewScreenNotOpened_thenOpensIt() {
        walletService.receive_output = "id"
        mainFlowCoordinator.setUp()
        mainFlowCoordinator.receive(message: ["key": "value"])
        delay()
        let vc = mainFlowCoordinator.navigationController.topViewController
            as? TransactionReviewViewController
        XCTAssertNotNil(vc)
        XCTAssertEqual(vc?.transactionID, "id")
        XCTAssertTrue(vc?.delegate === mainFlowCoordinator)
    }

    func test_whenAlreadyOpenedReviewTransaction_thenJustUpdatesIt() {
        walletService.receive_output = "id"
        walletService.transactionData_output = TransactionData(id: "some",
                                                               sender: "some",
                                                               recipient: "some",
                                                               amount: 100,
                                                               token: "ETH",
                                                               fee: 0,
                                                               status: .waitingForConfirmation)
        mainFlowCoordinator.setUp()
        mainFlowCoordinator.receive(message: ["key": "value"])
        delay()
        let controllerCount = mainFlowCoordinator.navigationController.viewControllers.count
        walletService.receive_output = "id2"
        mainFlowCoordinator.receive(message: ["key": "value"])
        delay()
        XCTAssertEqual((mainFlowCoordinator.navigationController.topViewController
            as? TransactionReviewViewController)?.transactionID, "id2")
        XCTAssertEqual(mainFlowCoordinator.navigationController.viewControllers.count, controllerCount)
    }

    func test_whenReviewTransactionFinished_thenPopsBack() {
        mainFlowCoordinator.setUp()
        delay()
        let vc = mainFlowCoordinator.navigationController.topViewController
        mainFlowCoordinator.createNewTransaction()
        delay()
        mainFlowCoordinator.transactionReviewViewControllerDidFinish()
        delay()
        XCTAssertTrue(vc === mainFlowCoordinator.navigationController.topViewController)
    }

    func test_whenUserIsAuthenticated_thenTransactionCanSubmit() throws {
        try authenticationService.registerUser(password: "pass")
        authenticationService.allowAuthentication()
        _ = try authenticationService.authenticateUser(.password("pass"))
        let exp = expectation(description: "submit")
        mainFlowCoordinator.transactionReviewViewControllerWantsToSubmitTransaction { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func test_whenUserNotAuthenticated_thenPresentsUnlockVC() throws {
        mainFlowCoordinator.setUp()
        createWindow(mainFlowCoordinator.rootViewController)
        let exp = expectation(description: "submit")
        try authenticationService.registerUser(password: "111111A")
        authenticationService.allowAuthentication()
        mainFlowCoordinator.transactionReviewViewControllerWantsToSubmitTransaction { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }
        delay()
        let vc = mainFlowCoordinator.navigationController.topViewController?.presentedViewController
            as! UnlockViewController
        vc.textInput.text = "111111A"
        _ = vc.textInput.textFieldShouldReturn(UITextField())
        waitForExpectations(timeout: 1)
    }

}