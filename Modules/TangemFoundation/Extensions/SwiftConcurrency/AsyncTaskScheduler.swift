//
//  AsyncTaskScheduler.swift
//  TangemModules
//
//  Created by Andrew Son on 14.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public class AsyncTaskScheduler {
    private var task: Task<Void, Error>?

    public var isScheduled: Bool {
        !(task?.isCancelled ?? true)
    }

    public init() {}

    public func scheduleJob(interval: TimeInterval, repeats: Bool, action: @escaping () async throws -> Void) {
        task?.cancel()
        task = Task {
            repeat {
                try await Task.sleep(seconds: interval)
                try Task.checkCancellation()
                try await action()
            } while !Task.isCancelled && repeats
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }
}
