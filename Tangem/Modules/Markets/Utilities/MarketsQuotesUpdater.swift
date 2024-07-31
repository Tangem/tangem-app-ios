//
//  MarketsQuotesUpdater.swift
//  Tangem
//
//  Created by Andrew Son on 30/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class MarketsQuotesUpdater {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let lock = Lock(isRecursive: false)
    private let quotesUpdateTimeInterval: TimeInterval = 60.0

    private var updateList = Set<String>()
    private var task: AsyncTaskScheduler = .init()

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

    func pauseUpdates() {
        task.cancel()
    }

    func resumeUpdates() {
        setupUpdateTask()
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
        if updateList.isEmpty {
            return
        }
        let quotesToUpdate = Array(updateList)
        await quotesRepository.loadQuotes(currencyIds: quotesToUpdate)
    }
}
