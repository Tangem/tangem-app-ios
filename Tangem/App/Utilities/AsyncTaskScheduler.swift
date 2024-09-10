//
//  AsyncTaskScheduler.swift
//  Tangem
//
//  Created by Andrew Son on 17/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class AsyncTaskScheduler {
    private var task: Task<Void, Error>?

    var isScheduled: Bool {
        !(task?.isCancelled ?? true)
    }

    func scheduleJob(interval: TimeInterval, repeats: Bool, action: @escaping () async throws -> Void) {
        task?.cancel()
        task = Task {
            repeat {
                try await Task.sleep(seconds: interval)
                try Task.checkCancellation()
                try await action()
            } while !Task.isCancelled && repeats
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
