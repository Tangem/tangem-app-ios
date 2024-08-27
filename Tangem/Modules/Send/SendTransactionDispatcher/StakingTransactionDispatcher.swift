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
    private let stakingTransactionMapper: StakingTransactionMapper

    private var transactionSentResult: [TransactionSentResult] = []

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner,
        pendingHashesSender: StakingPendingHashesSender,
        stakingTransactionMapper: StakingTransactionMapper
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.pendingHashesSender = pendingHashesSender
        self.stakingTransactionMapper = stakingTransactionMapper
    }
}

// MARK: - SendTransactionDispatcher

extension StakingTransactionDispatcher: SendTransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .staking(let action) = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = SendTransactionMapper()

        do {
            if let cachedResult = try await sendCachedResultIfNeeded() {
                return cachedResult
            }

            let transactions = stakingTransactionMapper.mapToStakeKitTransactions(action: action)
            let results = try await sendStakeKit(transactions: transactions)
            assert(action.transactions.count == results.count)

            transactionSentResult = action.transactions.indexed().map { index, transaction in
                TransactionSentResult(id: transaction.id, result: results[index])
            }

            if let cachedResult = try await sendCachedResultIfNeeded() {
                return cachedResult
            }

            throw SendTransactionDispatcherResult.Error.resultNotFound

        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingTransactionDispatcher {
    func sendCachedResultIfNeeded() async throws -> SendTransactionDispatcherResult? {
        guard !transactionSentResult.isEmpty else {
            return nil
        }

        var dispatcherResult: SendTransactionDispatcherResult?
        for result in transactionSentResult {
            dispatcherResult = try await sendHash(result: result)
            transactionSentResult.removeAll(where: { $0.id == result.id })
        }

        guard let dispatcherResult else {
            throw SendTransactionDispatcherResult.Error.resultNotFound
        }

        return dispatcherResult
    }

    func stakeKitTransactionSender() throws -> StakeKitTransactionSender {
        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            throw SendTransactionDispatcherResult.Error.stakingUnsupported
        }

        return stakeKitTransactionSender
    }

    func sendStakeKit(transactions: [StakeKitTransaction]) async throws -> [TransactionSendResult] {
        let sender = try stakeKitTransactionSender()
        let result: [TransactionSendResult]

        if transactions.count == 1, let tx = transactions.first {
            result = try await sender.sendStakeKit(.single(tx), signer: transactionSigner)
        } else {
            result = try await sender.sendStakeKit(.multiple(transactions), signer: transactionSigner)
        }

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
