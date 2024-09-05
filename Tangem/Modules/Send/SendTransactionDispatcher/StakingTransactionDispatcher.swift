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

    private var stuck: Stuck? = .none

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
            switch stuck?.type {
            case .none:
                return try await sendStakeKit(action: action)

            case .sendHash(let result) where action.transactions.last?.id == result.transaction.id:
                // If it was the last transaction then return
                let transactionDispatcherResult = try await sendHash(action: action, result: result)
                stuck = .none
                return transactionDispatcherResult

            case .sendHash(let result):
                let index = action.transactions.firstIndex(where: { $0.id == result.transaction.id })
                let transactionDispatcherResult = try await sendStakeKit(action: action, offset: index)
                stuck = .none
                return transactionDispatcherResult

            case .send(let transaction):
                let index = action.transactions.firstIndex(where: { $0.id == transaction.id })
                let transactionDispatcherResult = try await sendStakeKit(action: action, offset: index)
                stuck = .none
                return transactionDispatcherResult
            }
        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingTransactionDispatcher {
    func stakeKitTransactionSender() throws -> StakeKitTransactionSender {
        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            throw Errors.stakingUnsupported
        }

        return stakeKitTransactionSender
    }

    func sendStakeKit(action: StakingTransactionAction, offset: Int? = .none) async throws -> SendTransactionDispatcherResult {
        let sender = try stakeKitTransactionSender()
        var transactions = stakingTransactionMapper.mapToStakeKitTransactions(action: action)

        if let offset {
            transactions = Array(transactions[offset...])
        }

        let stream = sender.sendStakeKit(transactions: transactions, signer: transactionSigner, delay: 5)

        var transactionDispatcherResult: SendTransactionDispatcherResult?

        do {
            for try await result in stream {
                transactionDispatcherResult = try await sendHash(action: action, result: result)
            }
        } catch let error as StakeKitTransactionSendError {
            stuck = .init(action: action, type: .send(transaction: error.transaction))
            throw error.error
        } catch {
            throw error
        }

        guard let transactionDispatcherResult else {
            throw Errors.resultNotFound
        }

        walletModel.updateAfterSendingTransaction()
        return transactionDispatcherResult
    }

    func sendHash(action: StakingTransactionAction, result: StakeKitTransactionSendResult) async throws -> SendTransactionDispatcherResult {
        let hash = StakingPendingHash(transactionId: result.transaction.id, hash: result.result.hash)
        do {
            try await pendingHashesSender.sendHash(hash)
        } catch {
            stuck = .init(action: action, type: .sendHash(result: result))
            throw error
        }

        return SendTransactionMapper().mapResult(result.result, blockchain: walletModel.blockchainNetwork.blockchain)
    }
}

extension StakingTransactionDispatcher {
    struct Stuck: Hashable {
        let action: StakingTransactionAction
        let type: StuckType
    }

    enum StuckType: Hashable {
        case send(transaction: StakeKitTransaction)
        case sendHash(result: StakeKitTransactionSendResult)
    }

    enum Errors: Error {
        case stakingUnsupported
        case resultNotFound
    }
}
