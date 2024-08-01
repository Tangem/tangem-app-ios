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

    func send(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never>
}

enum SendTransactionDispatcherResult {
    case informationRelevanceServiceError
    case informationRelevanceServiceFeeWasIncreased

    case transactionNotFound
    case userCancelled
    case sendTxError(transaction: BSDKTransaction, error: SendTxError)
    case success(url: URL?)

    case demoAlert
}

class CommonSendTransactionDispatcher {
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner

    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }
}

// MARK: - SendTransactionDispatcher

extension CommonSendTransactionDispatcher: SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func send(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard case .transfer(let transaction) = transaction else {
            return .just(output: .transactionNotFound)
        }

        _isSending.send(true)

        return walletModel
            .send(transaction, signer: transactionSigner)
            .mapToResult()
            .withWeakCaptureOf(self)
            .map { sender, result in
                sender._isSending.send(false)

                return sender.proceed(transaction: transaction, result: result)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonSendTransactionDispatcher {
    private func proceed(transaction: BSDKTransaction, result: Result<TransactionSendResult, SendTxError>) -> SendTransactionDispatcherResult {
        switch result {
        case .success(let result):
            return proceed(transaction: transaction, result: result)
        case .failure(let error):
            return proceed(transaction: transaction, error: error)
        }
    }

    private func proceed(transaction: BSDKTransaction, result: TransactionSendResult) -> SendTransactionDispatcherResult {
        if walletModel.isDemo {
            return .demoAlert
        }

        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        let explorerUrl = provider.url(transaction: result.hash)

        return .success(url: explorerUrl)
    }

    private func proceed(transaction: BSDKTransaction, error: SendTxError) -> SendTransactionDispatcherResult {
        switch error.error {
        case TangemSdkError.userCancelled:
            return .userCancelled
        default:
            return .sendTxError(transaction: transaction, error: error)
        }
    }
}
