//
//  SendTransactionDispatcher.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import struct BlockchainSdk.SendTxError

protocol SendTransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult
}

struct SendTransactionDispatcherResult: Hashable {
    let hash: String
    let url: URL?
    let signerType: String
}

extension SendTransactionDispatcherResult {
    enum Error: Swift.Error, LocalizedError {
        case informationRelevanceServiceError
        case informationRelevanceServiceFeeWasIncreased

        case transactionNotFound
        case userCancelled
        case loadTransactionInfo(error: Swift.Error)
        case sendTxError(transaction: SendTransactionType, error: SendTxError)

        case demoAlert

        var errorDescription: String? {
            switch self {
            case .sendTxError(_, let error):
                return error.localizedDescription
            case .loadTransactionInfo(let error):
                return error.localizedDescription
            case .demoAlert:
                return "Demo mode"
            case .informationRelevanceServiceError:
                return "Service error"
            case .informationRelevanceServiceFeeWasIncreased:
                return "Fee was increased"
            case .transactionNotFound:
                return "Transaction not found"
            case .userCancelled:
                return "User cancelled"
            }
        }
    }
}
