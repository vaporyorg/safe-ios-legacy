//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import MultisigWalletApplication
import MultisigWalletDomainModel
import CommonTestSupport

class EventRelayTests: XCTestCase {

    var relay: EventRelay!
    let subscriber = MockSubscriber()
    let publisher = EventPublisher()

    override func setUp() {
        super.setUp()
        relay = EventRelay(publisher: publisher)
    }

    func test_whenSubscriberDeallocated_thenNotNotified() {
        var callCount = 0
        let expectation = self.expectation(description: "Finished")
        var temp: BlockSubscriber? = BlockSubscriber {
            callCount += 1
            if callCount == 1 {
                expectation.fulfill()
            }
        }
        relay.subscribe(temp!, for: DomainEvent.self)
        publisher.publish(MyEvent())
        delay()
        temp = nil
        publisher.publish(MyEvent())
        delay()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(callCount, 1)
    }

    func test_whenSubscribingTwice_thenNotifiesCorrectly() {
        let other = MockSubscriber()
        subscriber.expect_notify()
        other.expect_notify()
        relay.subscribe(subscriber, for: DomainEvent.self)
        relay.subscribe(other, for: DomainEvent.self)
        publisher.publish(MyEvent())
        delay()
        subscriber.verify()
        other.verify()
    }

    func test_whenUnsubscribed_thenNotNotified() {
        relay.subscribe(subscriber, for: DomainEvent.self)
        relay.unsubscribe(subscriber)
        publisher.publish(MyEvent())
        subscriber.verify()
    }

    func test_whenReset_thenNotNotified() {
        relay.subscribe(subscriber, for: DomainEvent.self)
        relay.unsubscribe(subscriber)
        publisher.publish(MyEvent())
        subscriber.verify()
    }

}

class QuarantineEventRelayTests: XCTestCase {

    var relay: EventRelay!
    let subscriber = MockSubscriber()
    let publisher = EventPublisher()

    override func setUp() {
        super.setUp()
        relay = EventRelay(publisher: publisher)
    }

    func test_api() {
        relay.subscribe(subscriber, for: MyEvent.self)
        subscriber.expect_notify()
        publisher.publish(MyEvent())
        delay()
        subscriber.verify()
    }

}

class BlockSubscriber: EventSubscriber {

    var block: () -> Void

    init(_ block: @escaping () -> Void) {
        self.block = block
    }

    func notify() {
        block()
    }

}

class MockSubscriber: EventSubscriber {

    private var expected_notify = [String]()
    private var actual_notify = [String]()

    func expect_notify() {
        expected_notify.append("notify()")
    }

    func notify() {
        actual_notify.append(#function)
    }

    func verify(file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(actual_notify, expected_notify, file: file, line: line)
    }
}

class MyEvent: DomainEvent {}
