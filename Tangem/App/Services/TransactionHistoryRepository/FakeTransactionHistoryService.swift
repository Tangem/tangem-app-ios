//
//  FakeTransactionHistoryService.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import class TangemSwapping.ThreadSafeContainer

class FakeTransactionHistoryService {
    private let blockchain: Blockchain
    private let address: String
    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)

    init(
        blockchain: Blockchain,
        address: String
    ) {
        self.blockchain = blockchain
        self.address = address
    }
}

// MARK: - TransactionHistoryService

extension FakeTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        return FakeTransactionHistoryFactory().createFakeTxs(address: address, currencyCode: blockchain.currencySymbol)
    }

    var canFetchMore: Bool {
        false
    }

    func reset() {
        AppLog.shared.debug("\(self) was reset")
    }

    func update() -> AnyPublisher<Void, Never> {
        switch _state.value {
        case .initial:
            _state.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._state.value = .failedToLoad("Failed to load tx history")
                    return ()
                }
                .eraseToAnyPublisher()
        case .failedToLoad:
            _state.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._state.value = .loaded
                    return ()
                }
                .eraseToAnyPublisher()
        case .loaded:
            _state.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._state.value = .initial
                    return ()
                }
                .eraseToAnyPublisher()
        case .loading:
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._state.value = .loaded
                    return ()
                }
                .eraseToAnyPublisher()
        }
    }
}
