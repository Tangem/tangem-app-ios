//
//  MarketsQuotesUpdatesScheduler.swift
//  Tangem
//
//  Created by Andrew Son on 30/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class MarketsQuotesUpdatesScheduler {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let lock = Lock(isRecursive: false)
    private let quotesUpdateTimeInterval: TimeInterval = 60.0

    private var updateList = Set<String>()
    private var task: AsyncTaskScheduler = .init()
    private var forceUpdateTask: AnyCancellable?
    private var quotesLastUpdateDate: Date?

    func scheduleQuotesUpdate(for tokenIDs: Set<String>) {
        lock {
            updateList.formUnion(tokenIDs)
        }
    }

    func stopUpdatingQuotes(for tokenIDs: Set<String>) {
        lock {
            tokenIDs.forEach {
                updateList.remove($0)
            }
        }
    }

    func cancelUpdates() {
        task.cancel()
        forceUpdateTask?.cancel()
        forceUpdateTask = nil
    }

    func resumeUpdates() {
        setupUpdateTask()
    }

    func forceUpdate() {
        cancelUpdates()
        let date = Date()
        let lastUpdateDate = quotesLastUpdateDate ?? date
        let remainingTime = max(quotesUpdateTimeInterval - date.timeIntervalSince(lastUpdateDate), 0)
        forceUpdateTask = Task.delayed(withDelay: remainingTime, operation: { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.updateQuotes()
                try Task.checkCancellation()
                self?.setupUpdateTask()
                self?.forceUpdateTask = nil
            } catch {
                if !error.isCancellationError {
                    self?.forceUpdateTask = nil
                }
            }
        }).eraseToAnyCancellable()
    }

    func resetUpdates() {
        cancelUpdates()
        setupUpdateTask()
    }

    func saveQuotesUpdateDate(_ date: Date) {
        quotesLastUpdateDate = date
    }

    private func setupUpdateTask() {
        if task.isScheduled {
            return
        }

        task.scheduleJob(interval: quotesUpdateTimeInterval, repeats: true, action: { [weak self] in
            await self?.updateQuotes()
        })
    }

    private func updateQuotes() async {
        let quotesToUpdate = lock { Array(updateList) }

        if quotesToUpdate.isEmpty {
            return
        }

        saveQuotesUpdateDate(Date())
        await quotesRepository.loadQuotes(currencyIds: quotesToUpdate)
    }
}
