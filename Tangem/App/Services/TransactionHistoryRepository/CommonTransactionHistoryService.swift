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
import class TangemSwapping.ThreadSafeContainer

class CommonTransactionHistoryService {
    private let blockchain: Blockchain
    private let address: String

    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private var totalPages = 0
    private var currentPage = 0
    private let pageSize: Int = 20
    private var cancellable: AnyCancellable?
    private var storage: ThreadSafeContainer<[TransactionRecord]> = []

    init(
        blockchain: Blockchain,
        address: String,
        transactionHistoryProvider: TransactionHistoryProvider
    ) {
        self.blockchain = blockchain
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

    var canFetchMore: Bool {
        currentPage < totalPages
    }

    func reset() {
        cancellable = nil
        currentPage = 0
        totalPages = 0
        updateStorage(records: [])
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

        guard currentPage == 0 || canFetchMore else {
            AppLog.shared.debug("\(self) reached the end of list")
            return
        }

        AppLog.shared.debug("\(self) start loading")
        _state.send(.loading)

        let nextPage = Page(number: currentPage + 1, size: pageSize)
        cancellable = transactionHistoryProvider
            .loadTransactionHistory(address: address, page: nextPage)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLog.shared.debug("\(String(describing: self)) error: \(error)")
                case .finished:
                    self?._state.send(.loaded)
                }
            } receiveValue: { [weak self] response in
                self?.totalPages = response.totalPages
                self?.currentPage = response.page.number
                self?.addToStorage(records: response.records)
                AppLog.shared.debug("\(String(describing: self)) loaded")
                result(.success(()))
            }
    }

    func updateStorage(records: [TransactionRecord]) {
        storage.mutate { value in
            value = records
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
                "blockchain": blockchain.displayName,
                "address": address,
                "totalPages": totalPages,
                "currentPage": currentPage,
            ]
        )
    }
}
