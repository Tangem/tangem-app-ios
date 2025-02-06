//
//  BackgroundTaskWrapper.swift
//  Tangem
//
//  Created by Andrey Fedorov on 25.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

/// Lightweight wrapper for the RAII-like lifetime management of iOS background tasks created
/// using `UIApplication.beginBackgroundTask(withName:expirationHandler:)` system API.
/// Based on https://developer.apple.com/forums/thread/729335
final class BackgroundTaskWrapper {
    typealias ExpirationHandler = () -> Void

    private let taskName: String
    private var expirationHandler: ExpirationHandler?
    private var taskIdentifier: UIBackgroundTaskIdentifier
    private let criticalSection = Lock(isRecursive: false)

    init(
        taskName: String = BackgroundTaskWrapper.makeTaskName(),
        expirationHandler: ExpirationHandler? = nil
    ) {
        self.taskName = taskName
        self.expirationHandler = expirationHandler
        taskIdentifier = .invalid
        start()
    }

    deinit {
        finish(isExpired: false)
    }

    func finish() {
        finish(isExpired: false)
    }

    private func start() {
        taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: taskName) { [weak self] in
            self?.finish(isExpired: true)
        }
    }

    private func finish(isExpired: Bool) {
        criticalSection {
            guard taskIdentifier != .invalid else {
                return
            }

            UIApplication.shared.endBackgroundTask(taskIdentifier)
            taskIdentifier = .invalid

            if isExpired {
                expirationHandler?()
            }

            expirationHandler = nil

            AppLogger.warning("Background task '\(taskName)' finished (expired: \(isExpired))")
        }
    }
}

// MARK: - Convenience extensions

private extension BackgroundTaskWrapper {
    static func makeTaskName() -> String {
        return String(describing: type(of: self)) + "_" + UUID().uuidString
    }
}
