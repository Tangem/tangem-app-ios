//
//  CommonTransactionHistoryService.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemFoundation

class CommonTransactionHistoryService {
    private let tokenItem: TokenItem
    private let address: String

    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let pageSize: Int = 100
    private var cancellable: AnyCancellable?
    private var storage: ThreadSafeContainer<[TransactionRecord]> = []

    init(
        tokenItem: TokenItem,
        address: String,
        transactionHistoryProvider: TransactionHistoryProvider
    ) {
        self.tokenItem = tokenItem
        self.address = address
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

// MARK: - TransactionHistoryService

extension CommonTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        return storage.read()
    }

    var canFetchHistory: Bool {
        transactionHistoryProvider.canFetchHistory
    }

    func clearHistory() {
        cancellable = nil
        transactionHistoryProvider.reset()
        cleanStorage()
        AppLog.shared.debug("\(self) was reset")
    }

    func update() -> AnyPublisher<Void, Never> {
        Deferred {
            Future { [weak self] promise in
                self?.fetch(result: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonTransactionHistoryService {
    func fetch(result: @escaping (Result<Void, Never>) -> Void) {
        cancellable = nil

        guard canFetchHistory else {
            AppLog.shared.debug("\(self) reached the end of list")
            result(.success(()))
            return
        }

        AppLog.shared.debug("\(self) start loading")
        _state.send(.loading)

        let request = TransactionHistory.Request(address: address, amountType: tokenItem.amountType, limit: pageSize)

        cancellable = transactionHistoryProvider
            .loadTransactionHistory(request: request)
            .handleEvents(receiveCancel: { [weak self] in
                // Resolves conflicting requests for tracking history from different consumers so as not to lose output from the update process
                AppLog.shared.debug("\(String(describing: self)) canceled")
                result(.success(()))
            })
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLog.shared.debug("\(String(describing: self)) error: \(error)")
                    result(.success(()))
                case .finished:
                    self?._state.send(.loaded)
                    AppLog.shared.debug("\(String(describing: self)) loaded")
                    result(.success(()))
                }
            } receiveValue: { [weak self] response in
                self?.addToStorage(records: response.records)
            }
    }

    func cleanStorage() {
        storage.mutate { value in
            value.removeAll()
        }
    }

    func addToStorage(records: [TransactionRecord]) {
        storage.mutate { value in
            value += records
        }
    }
}

// MARK: - CustomStringConvertible

extension CommonTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "address": address,
                "request": transactionHistoryProvider.description,
            ]
        )
    }
}
