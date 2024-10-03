//
//  AccountHealthCheckBackgroundTask.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// An abstract interface for the ongoing account health check, running
/// as a background task (using API from BackgroundTasks, UIKit, etc).
protocol AccountHealthCheckBackgroundTask {
    func finish()
}

// MARK: - AccountHealthCheckBackgroundTask protocol conformance

extension BackgroundTaskWrapper: AccountHealthCheckBackgroundTask {}
