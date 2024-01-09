//
//  MutipleAddressTransactionHistoryService.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import class TangemSwapping.ThreadSafeContainer

class MutipleAddressTransactionHistoryService {
    private let tokenItem: TokenItem
    private let addresses: [String]

    private let transactionHistoryProvider: TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private var totalPages: [String: Int] = [:]
    private var currentPage: [String: Int] = [:]
    private let pageSize: Int = 20
    private var cancellable: AnyCancellable?
    private var storage: ThreadSafeContainer<[TransactionRecord]> = []

    init(
        tokenItem: TokenItem,
        addresses: [String],
        transactionHistoryProvider: TransactionHistoryProvider
    ) {
        self.tokenItem = tokenItem
        self.addresses = addresses
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

// MARK: - TransactionHistoryService

extension MutipleAddressTransactionHistoryService: TransactionHistoryService {
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
        addresses.contains {
            currentPage[$0, default: 0] < totalPages[$0, default: 0]
        }
    }

    func clearHistory() {
        cancellable = nil
        currentPage = [:]
        totalPages = [:]
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

private extension MutipleAddressTransactionHistoryService {
    /// `Publisher` with the tuple value that contains the address and the history response by the one page
    typealias LoadingPublisher = AnyPublisher<(address: String, response: TransactionHistory.Response), Error>

    func fetch(result: @escaping (Result<Void, Never>) -> Void) {
        if _state.value.isLoading {
            AppLog.shared.debug("\(self) already is loading")
            return
        }

        cancellable = nil

        // Collect publishers for the next page if the page is exist
        let publishers: [LoadingPublisher] = addresses.compactMap { address in
            guard currentPage[address, default: 0] == 0 || canFetchHistory else {
                AppLog.shared.debug("Address \(address) in \(self) reached the end of list")
                return nil
            }

            return loadTransactionHistory(address: address)
        }

        if publishers.isEmpty {
            AppLog.shared.debug("\(self) all addresses reached the end of list")
            result(.success(()))
            return
        }

        AppLog.shared.debug("\(self) start loading")
        _state.send(.loading)

        cancellable = Publishers
            .MergeMany(publishers)
            .collect()
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLog.shared.debug("\(String(describing: self)) error: \(error)")
                    result(.success(()))
                case .finished:
                    self?._state.send(.loaded)
                }
            } receiveValue: { service, responses in
                for response in responses {
                    service.totalPages[response.address] = response.response.totalPages
                    service.currentPage[response.address] = response.response.page.number
                    service.addToStorage(records: response.response.records)

                    AppLog.shared.debug("Address \(response.address) in \(String(describing: self)) loaded")
                }

                result(.success(()))
            }
    }

    func loadTransactionHistory(address: String) -> LoadingPublisher {
        let nextPage = Page(number: currentPage[address, default: 0] + 1, size: pageSize)
        let request = TransactionHistory.Request(address: address, page: nextPage, amountType: tokenItem.amountType)
        return transactionHistoryProvider
            .loadTransactionHistory(request: request)
            .map { (address: address, response: $0) }
            .eraseToAnyPublisher()
    }

    func append(newRecords: [TransactionRecord], in records: inout [TransactionRecord]) {
        for record in newRecords {
            // If we already have the transaction record
            // Just append new sources and new destinations in the record
            if let index = records.firstIndex(where: { $0.hash == record.hash }) {
                let oldRecord = records[index]
                records[index] = TransactionRecord(
                    hash: record.hash,
                    source: oldRecord.source + record.source,
                    destination: oldRecord.destination + record.destination,
                    fee: oldRecord.fee,
                    status: oldRecord.status,
                    isOutgoing: oldRecord.isOutgoing,
                    type: oldRecord.type,
                    date: oldRecord.date,
                    tokenTransfers: oldRecord.tokenTransfers
                )

                AppLog.shared.debug("TransactionRecord with hash: \(record.hash) was zipped")
            } else {
                records.append(record)
            }
        }
    }

    func cleanStorage() {
        storage.mutate { value in
            value.removeAll()
        }
    }

    func addToStorage(records: [TransactionRecord]) {
        storage.mutate { [weak self] value in
            self?.append(newRecords: records, in: &value)
        }
    }
}

// MARK: - CustomStringConvertible

extension MutipleAddressTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "totalPages": totalPages,
                "currentPage": currentPage,
            ]
        )
    }
}

private extension TransactionRecord.SourceType {
    static func + (lhs: Self, rhs: Self) -> Self {
        let lhsList: [TransactionRecord.Source] = {
            switch lhs {
            case .single(let source):
                return [source]
            case .multiple(let sources):
                return sources
            }
        }()

        let rhsList: [TransactionRecord.Source] = {
            switch rhs {
            case .single(let source):
                return [source]
            case .multiple(let sources):
                return sources
            }
        }()

        // We add the "unique" here because the input may exist twice
        let list = (lhsList + rhsList).unique()
        if list.count == 1, let first = list.first {
            return .single(first)
        }

        return .multiple(list)
    }
}

private extension TransactionRecord.DestinationType {
    static func + (lhs: Self, rhs: Self) -> Self {
        let lhsList: [TransactionRecord.Destination] = {
            switch lhs {
            case .single(let source):
                return [source]
            case .multiple(let sources):
                return sources
            }
        }()

        let rhsList: [TransactionRecord.Destination] = {
            switch rhs {
            case .single(let source):
                return [source]
            case .multiple(let sources):
                return sources
            }
        }()

        // We add the "unique" here because the change may exist twice
        let list = (lhsList + rhsList).unique()
        if list.count == 1, let first = list.first {
            return .single(first)
        }

        return .multiple(list)
    }
}
