//
//  SendTransactionDispatcher.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import enum TangemSdk.TangemSdkError

protocol SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { get }

    func sendPublisher(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never>
    func send(transaction: SendTransactionType) async throws -> String
}

enum SendTransactionDispatcherResult {
    case informationRelevanceServiceError
    case informationRelevanceServiceFeeWasIncreased

    case transactionNotFound
    case userCancelled
    case sendTxError(transaction: SendTransactionType, error: SendTxError)
    case success(hash: String, url: URL?)

    case demoAlert

    case stakingUnsupported
}

enum SendTransactionDispatcherError: Error {
    case transactionNotFound
}
