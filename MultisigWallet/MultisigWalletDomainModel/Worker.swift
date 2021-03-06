//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common

public struct RepeatingShouldStop {
    public static let yes = true
    public static let no = false
}

/// Worker is used for tasks that should repeat untill an expectation is met.
public class Worker: Assertable {

    enum Error: String, LocalizedError, Hashable {
        case invalidRepatingTimeInterval
    }

    private let jobClosure: () -> Bool
    private let interval: TimeInterval
    private var shouldStop: Bool = false

    /// Start a Worker repeating each interval until the block resolves to true.
    ///
    /// - Parameters:
    ///   - interval: TimeInterval to repeat the task.
    ///   - block: returns whether the Worket should contunue.
    public static func start(repeating interval: TimeInterval, block: @escaping () -> Bool) {
        let worker = Worker(repeating: interval, block: block)
        worker.start()
    }

    public init(repeating interval: TimeInterval, block: @escaping () -> Bool) {
        self.interval = interval
        self.jobClosure = block
        try! assertTrue(interval > 0, Error.invalidRepatingTimeInterval)
    }

    func start() {
        RunLoop.current.perform { // delay block until next run loop iteration
            while !self.shouldStop {
                self.shouldStop = self.jobClosure()
                if !self.shouldStop {
                    self.blockingWait()
                }
            }
        }
        runLoop()
    }

    private func blockingWait() {
        if Thread.isMainThread {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: self.interval))
        } else {
            usleep(UInt32(self.interval) * 1_000_000)
        }
    }

    private func runLoop() {
        if Thread.isMainThread {
            // on main thread, the RunLoop is already configured and running, so nothing to do.
            return
        }
        while !shouldStop {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1)) // allows RunLoop blocks processing
        }
    }

}
