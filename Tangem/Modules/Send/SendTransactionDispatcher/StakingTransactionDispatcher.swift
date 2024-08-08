//
//  StakingTransactionDispatcher.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemStaking

class StakingTransactionDispatcher {
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let pendingHashesSender: StakingPendingHashesSender

    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    private var transactionSendResult: TransactionSendResult?

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner,
        pendingHashesSender: StakingPendingHashesSender
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.pendingHashesSender = pendingHashesSender
    }
}

// MARK: - SendTransactionDispatcher

extension StakingTransactionDispatcher: SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func sendPublisher(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard case .staking(let stakeKitTransaction) = transaction else {
            return .just(output: .transactionNotFound)
        }

        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            return .just(output: .stakingUnsupported)
        }

        let sendPublisher = transactionSendResult.map {
            Just($0)
                .setFailureType(to: SendTxError.self)
                .eraseToAnyPublisher()
        }
            ?? stakeKitTransactionSender
            .sendStakeKit(transaction: stakeKitTransaction, signer: transactionSigner)
            .eraseToAnyPublisher()

        _isSending.send(true)

        return sendPublisher
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] transactionSendResult in
                    self?.transactionSendResult = transactionSendResult
                },
                receiveCompletion: { [weak self] completion in
                    self?._isSending.send(false)

                    if case .finished = completion {
                        self?.walletModel.updateAfterSendingTransaction()
                    }
                }
            )
            .withWeakCaptureOf(self)
            .eraseError()
            .tryAsyncMap { args in
                let (model, transaction) = args
                let hash = StakingPendingHash(transactionId: "", hash: transaction.hash)
                try await model.pendingHashesSender.sendHash(hash)
                return transaction
            }
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
        fatalError("Not implemented")
    }
}

// MARK: - Private

private extension StakingTransactionDispatcher {
    private func handleCompletion(_ completion: Subscribers.Completion<SendTxError>) {
        _isSending.send(false)

        switch completion {
        case .finished:
            walletModel.updateAfterSendingTransaction()
        default:
            break
        }
    }
}
