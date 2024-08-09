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

    private var transactionSentResult: TransactionSentResult?

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
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .staking(let transactionId, let stakeKitTransaction) = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = SendTransactionMapper()

        do {
            if let transactionSentResult {
                return try await sendHash(result: transactionSentResult)
            }

            let result = try await sendStakeKit(transaction: stakeKitTransaction)
            let sentResult = TransactionSentResult(id: transactionId, result: result)
            // Save it if `sendHash` will failed
            transactionSentResult = sentResult

            let dispatcherResult = try await sendHash(result: sentResult)

            // Clear after success tx was successfully sent
            transactionSentResult = nil

            return dispatcherResult
        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingTransactionDispatcher {
    func stakeKitTransactionSender() throws -> StakeKitTransactionSender {
        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            throw SendTransactionDispatcherResult.Error.stakingUnsupported
        }

        return stakeKitTransactionSender
    }

    func sendStakeKit(transaction: StakeKitTransaction) async throws -> TransactionSendResult {
        let result = try await stakeKitTransactionSender()
            .sendStakeKit(transaction: transaction, signer: transactionSigner)
            .async()

        walletModel.updateAfterSendingTransaction()
        return result
    }

    func sendHash(result: TransactionSentResult) async throws -> SendTransactionDispatcherResult {
        let hash = StakingPendingHash(transactionId: result.id, hash: result.result.hash)
        try await pendingHashesSender.sendHash(hash)
        return SendTransactionMapper().mapResult(result.result, blockchain: walletModel.blockchainNetwork.blockchain)
    }
}

extension StakingTransactionDispatcher {
    struct TransactionSentResult {
        let id: String
        let result: TransactionSendResult
    }
}
