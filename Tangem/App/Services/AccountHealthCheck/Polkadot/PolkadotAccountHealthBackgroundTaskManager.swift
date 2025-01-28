//
//  PolkadotAccountHealthBackgroundTaskManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BackgroundTasks
import TangemFoundation

/// - Warning: Read-write access to all `@AppStorageCompat` or stored properties
/// must be synchronized (e.g. by using `runOnMain(_:)` helper).
final class PolkadotAccountHealthBackgroundTaskManager {
    typealias OnAccountCheck = (_ account: String, _ backgroundTask: AccountHealthCheckBackgroundTask) -> Void
    typealias OnResourcesCleanup = () -> Void

    private let backgroundTaskDelay: TimeInterval
    private let onAccountCheck: OnAccountCheck?
    private let onResourcesCleanup: OnResourcesCleanup?

    @AppStorageCompat(StorageKeys.pendingAccountsForBackgroundTask)
    private var pendingAccountsForBackgroundTask: [String] = []

    private var backgroundTaskIdentifier: String {
        let bundleIdentifier = InfoDictionaryUtils.bundleIdentifier.value() ?? ""
        return [
            bundleIdentifier,
            "PolkadotAccountHealthCheckTask",
        ].joined(separator: ".")
    }

    init(
        backgroundTaskDelay: TimeInterval,
        onAccountCheck: OnAccountCheck? = nil,
        onResourcesCleanup: OnResourcesCleanup? = nil
    ) {
        self.backgroundTaskDelay = backgroundTaskDelay
        self.onResourcesCleanup = onResourcesCleanup
        self.onAccountCheck = onAccountCheck
    }

    /// - Warning: Registration of all launch handlers must be complete before the end of applicationDidFinishLaunching(_:).
    func registerBackgroundTask() {
        let identifier = backgroundTaskIdentifier
        let isRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
            if let task = task as? BGProcessingTask {
                self?.handleBackgroundTask(task)
            } else {
                preconditionFailure("Unsupported type of background task (BackgroundTasks) '\(type(of: task))' received")
            }
        }

        if !isRegistered {
            let message = "Can't register background task (BackgroundTasks) with identifier '\(identifier)'"
            assertionFailure(message)
            AppLog.error(error: message)
        }
    }

    /// - Note: Submitting a task request for an unexecuted task that’s already in the queue replaces the previous task request,
    /// so it's perfectly fine to call this method multiple times.
    func scheduleBackgroundTask(for account: String) {
        pendingAccountsForBackgroundTask.append(account)

        let identifier = backgroundTaskIdentifier
        let taskRequest = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        taskRequest.requiresNetworkConnectivity = true
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: backgroundTaskDelay)

        do {
            try BGTaskScheduler.shared.submit(taskRequest)
            AppLog.info("Scheduled background task (BackgroundTasks) with identifier '\(identifier)'")
        } catch {
            let message = "Can't submit background task (BackgroundTasks) with identifier '\(identifier)'"
            assertionFailure(message)
            AppLog.error(error: message)
        }
    }

    func cancelAllBackgroundTasks() {
        let identifier = backgroundTaskIdentifier
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        pendingAccountsForBackgroundTask.removeAll()
        AppLog.info("Cancelled background task (BackgroundTasks) with identifier '\(identifier)'")
    }

    func cancelBackgroundTaskForAccount(_ account: String) {
        pendingAccountsForBackgroundTask.remove(account)
    }

    private func handleBackgroundTask(_ backgroundTask: BGProcessingTask) {
        AppLog.info("Processing background task (BackgroundTasks) with identifier '\(backgroundTask.identifier)'")

        let accounts = pendingAccountsForBackgroundTask.toSet()
        pendingAccountsForBackgroundTask.removeAll()

        backgroundTask.expirationHandler = { [weak self] in
            AppLog.info("Background task (BackgroundTasks) with identifier '\(backgroundTask.identifier)' has expired'")
            self?.onResourcesCleanup?()
            backgroundTask.setTaskCompleted(success: false)
        }

        let backgroundTaskWrapper = BGProcessingTaskWrapper(innerTask: backgroundTask, counter: accounts.count)

        if accounts.isEmpty {
            backgroundTaskWrapper.finish()
            return
        }

        for account in accounts {
            onAccountCheck?(account, backgroundTaskWrapper)
        }
    }
}

// MARK: - Auxiliary types

/// Won't allow inner wrapper task to finish until the certain criteria is met (`counter` is equal or less than zero).
private final class BGProcessingTaskWrapper: AccountHealthCheckBackgroundTask {
    private let innerTask: BGProcessingTask
    private var counter: Int

    init(innerTask: BGProcessingTask, counter: Int) {
        self.innerTask = innerTask
        self.counter = counter
    }

    func finish() {
        counter -= 1

        if counter <= 0 {
            innerTask.setTaskCompleted(success: true)
        }
    }
}

// MARK: - Constants

private extension PolkadotAccountHealthBackgroundTaskManager {
    enum StorageKeys: String {
        case pendingAccountsForBackgroundTask = "polkadot_account_health_background_task_manager_pending_accounts_for_background_task"
    }
}
