//
//  TransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public protocol TransactionHistoryProvider: CustomStringConvertible {
    var canFetchHistory: Bool { get }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error>
    func reset()
}

public extension TransactionHistoryProvider {
    func shouldBeIncludedInHistory(amountType: Amount.AmountType, record: TransactionRecord) -> Bool {
        switch amountType {
        case .coin where record.type == .transfer:
            break
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            break
        }
        
        switch record.destination {
        case .single(let destination):
            return destination.amount != 0
        case .multiple(let destinations):
            return destinations.contains { $0.amount != 0 }
        }
    }
}
