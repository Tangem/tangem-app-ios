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

extension StakingTransactionDispatcher: SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func sendPublisher(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard case .staking(let stakeKitTransaction) = transaction else {
            return .just(output: .transactionNotFound)
        }

        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            return .just(output: .stakingUnsupported)
        }

        _isSending.send(true)

        return stakeKitTransactionSender
            .sendStakeKit(transaction: stakeKitTransaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] completion in
                self?._isSending.send(false)

                if case .finished = completion {
                    self?.walletModel.updateAfterSendingTransaction()
                }
            })
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
