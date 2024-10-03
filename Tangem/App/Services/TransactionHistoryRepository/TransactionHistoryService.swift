//
//  TransactionHistoryService.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol TransactionHistoryService: AnyObject, TransactionHistoryFetcher {
    var state: TransactionHistoryServiceState { get }
    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> { get }

    var items: [TransactionRecord] { get }

    /// This method will be load the next page(current + 1) of transaction history records
    func update() -> AnyPublisher<Void, Never>
}

protocol TransactionHistoryFetcher {
    var canFetchHistory: Bool { get }

    /// Use this method for reset manager to first page
    func clearHistory()
}
