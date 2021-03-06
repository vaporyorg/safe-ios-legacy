//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import MultisigWalletApplication
import CommonTestSupport
import Common
import SafeUIKit

class AssetViewViewControllerTests: SafeTestCase {

    let controller = AssetViewViewController()

    override func setUp() {
        super.setUp()
        walletService.visibleTokensOutput = [TokenData.eth, TokenData.gno, TokenData.mgn]
    }

    func test_whenCreated_thenLoadsData() {
        createWindow(controller)
        controller.notify()
        delay()
        XCTAssertEqual(controller.tableView.numberOfRows(inSection: 0), 3)
        let firstCell = cell(at: 0, 0)
        let secondCell = cell(at: 1, 0)
        let thirdCell = cell(at: 2, 0)
        XCTAssertEqual(firstCell.leftTextLabel.text, "ETH")
        XCTAssertEqual(firstCell.rightTextLabel.text?.replacingOccurrences(of: ",", with: "."), "0.01")
        XCTAssertEqual(secondCell.leftTextLabel.text, "GNO")
        XCTAssertEqual(secondCell.rightTextLabel.text?.replacingOccurrences(of: ",", with: "."), "1")
        XCTAssertEqual(thirdCell.leftTextLabel.text, "MGN")
        XCTAssertEqual(thirdCell.rightTextLabel.text, "--")
    }

    func test_whenUpdated_thenSyncs() {
        controller.update()
        delay(0.1)
        XCTAssertTrue(walletService.didSync)
    }

    func test_whenSelectingRow_thenCallsDelegate() {
        let delegate = MockMainViewControllerDelegate()
        controller.delegate = delegate
        controller.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(delegate.didCallCreateNewTransaction)
    }

    func test_whenThereAreNoTokens_thenTokensFooterIsShown() {
        walletService.visibleTokensOutput = [TokenData.eth]
        createWindow(controller)
        controller.notify()
        XCTAssertTrue(controller.tableView.tableFooterView is AddTokenFooterView)
    }

    func test_tracking() {
        XCTAssertTracksAppearance(in: controller, MainTrackingEvent.assets)
    }

}

private extension AssetViewViewControllerTests {

    func cell(at row: Int, _ section: Int) -> BasicTableViewCell {
        return controller.tableView.cellForRow(at: IndexPath(row: row, section: section)) as! BasicTableViewCell
    }

}
