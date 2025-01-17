//
//  MultipleAddressTransactionHistoryService.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemFoundation

class MultipleAddressTransactionHistoryService {
    private let tokenItem: TokenItem
    private let addresses: [String]

    private let transactionHistoryProviders: [String: TransactionHistoryProvider]

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let pageSize: Int = 100
    private var cancellable: AnyCancellable?
    private var storage: ThreadSafeContainer<[TransactionRecord]> = []

    init(
        tokenItem: TokenItem,
        addresses: [String],
        transactionHistoryProviders: [String: TransactionHistoryProvider]
    ) {
        assert(!transactionHistoryProviders.isEmpty, "TransactionHistoryProviders can't be empty")

        self.tokenItem = tokenItem
        self.addresses = addresses
        self.transactionHistoryProviders = transactionHistoryProviders
    }
}

// MARK: - TransactionHistoryService

extension MultipleAddressTransactionHistoryService: TransactionHistoryService {
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
            transactionHistoryProviders[$0]?.canFetchHistory ?? false
        }
    }

    func clearHistory() {
        cancellable = nil
        transactionHistoryProviders.forEach { _, provider in provider.reset() }
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

private extension MultipleAddressTransactionHistoryService {
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
            guard canFetchHistory else {
                AppLog.shared.debug("Address in \(self) reached the end of list")
                return nil
            }

            do {
                return try loadTransactionHistory(address: address)
            } catch {
                AppLog.shared.debug("Provider exception: \(error) publisher set be nil")
                return nil
            }
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
                    service.addToStorage(records: response.response.records)

                    AppLog.shared.debug("Address in \(String(describing: self)) loaded")
                }

                result(.success(()))
            }
    }

    func loadTransactionHistory(address: String) throws -> LoadingPublisher {
        let request = TransactionHistory.Request(address: address, amountType: tokenItem.amountType, limit: pageSize)

        guard let provider = transactionHistoryProviders[address] else {
            throw ServiceError.unknowProvider
        }

        return provider
            .loadTransactionHistory(request: request)
            .map { response in
                return (address: address, response: response)
            }
            .eraseToAnyPublisher()
    }

    func append(newRecords: [TransactionRecord], in records: inout [TransactionRecord]) {
        for record in newRecords {
            // If we already have the transaction record
            // Just append new sources and new destinations in the record
            if let index = records.firstIndex(where: { $0.hash == record.hash && $0.index == record.index }) {
                let oldRecord = records[index]
                records[index] = TransactionRecord(
                    hash: record.hash,
                    index: record.index,
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

extension MultipleAddressTransactionHistoryService {
    enum ServiceError: Error {
        case unknowProvider
    }
}

// MARK: - CustomStringConvertible

extension MultipleAddressTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "requests": transactionHistoryProviders.map { _, provider in
                    provider.description
                }.joined(separator: ", "),
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
