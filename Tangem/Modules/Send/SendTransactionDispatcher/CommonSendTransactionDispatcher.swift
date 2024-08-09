//
//  CommonSendTransactionDispatcher.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

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

    func sendPublisher(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard case .transfer(let transferTransaction) = transaction else {
            return .just(output: .transactionNotFound)
        }

        return send(transaction: transferTransaction)
            .withWeakCaptureOf(self)
            .map { sender, result in
                SendTransactionMapper().mapResult(
                    result,
                    blockchain: sender.walletModel.blockchainNetwork.blockchain
                )
            }
            .catch { SendTransactionMapper().mapError($0, transaction: transaction) }
            .eraseToAnyPublisher()
    }

    func send(transaction: SendTransactionType) async throws -> String {
        guard case .transfer(let transferTransaction) = transaction else {
            throw SendTransactionDispatcherError.transactionNotFound
        }

        let result = try await send(transaction: transferTransaction).async()
        return result.hash
    }
}

// MARK: - Private

private extension CommonSendTransactionDispatcher {
    func send(transaction: BSDKTransaction) -> AnyPublisher<TransactionSendResult, SendTxError> {
        _isSending.send(true)

        return walletModel.transactionSender
            .send(transaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?._isSending.send(false)

                if case .finished = completion {
                    self?.walletModel.updateAfterSendingTransaction()
                }
            })
            .eraseToAnyPublisher()
    }

    func handleCompletion(_ completion: Subscribers.Completion<SendTxError>) {
        _isSending.send(false)

        switch completion {
        case .finished:
            walletModel.updateAfterSendingTransaction()
        default:
            break
        }
    }
}
