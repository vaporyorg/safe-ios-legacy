//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import SafeAppUI
import Common

class OnboardingStepViewControllerTests: XCTestCase {

    var testContent = OnboardingStepInfo.testContent
    var vc: OnboardingStepViewController!

    override func setUp() {
        super.setUp()
        vc = OnboardingStepViewController.create(content: testContent)
    }

    func test_whenAppears_thenTracksEvent() {
        XCTAssertTracksAppearance(in: vc, testContent.trackingEvent as! ScreenTrackingEvent)
    }

    func test_whenUpdated_thenSetsContent() {
        vc.loadViewIfNeeded()
        vc.update(content: testContent)
        XCTAssertEqual(vc.imageView.image, testContent.image)
        XCTAssertEqual(vc.titleLabel.text, testContent.title)
        XCTAssertEqual(vc.descriptionLabel.text, testContent.description)
    }

    func test_whenViewNotLoaded_thenJustUpdatesContent() {
        testContent.title = "NewTitle"
        vc.update(content: testContent)
        XCTAssertEqual(vc.content?.title, "NewTitle")
    }

    func test_showInfo_callsInfoButtonAction() {
        vc.loadViewIfNeeded()
        var didCallAction = false
        vc.update(content: OnboardingStepInfo.testContentWith {
            didCallAction = true
        })
        vc.showInfo(self)
        XCTAssertTrue(didCallAction)
    }

}

extension OnboardingStepInfo {

    // swiftlint:disable trailing_closure
    static let testContent = OnboardingStepInfo(image: UIImage(),
                                                title: "TestTitle",
                                                description: "Test Description",
                                                actionTitle: "Test Action",
                                                trackingEvent: TestScreenTrackingEvent.view,
                                                action: {})

    static func testContentWith(infoAction: @escaping () -> Void) -> OnboardingStepInfo {
        return OnboardingStepInfo(image: UIImage(),
                                  title: "TestTitle",
                                  description: "Test Description",
                                  infoButtonAction: infoAction,
                                  actionTitle: "Test Action",
                                  trackingEvent: TestScreenTrackingEvent.view,
                                  action: {})
    }

}
