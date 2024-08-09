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

    private var cachedResult: CachedResult?

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
            if let cachedResult {
                let hash = StakingPendingHash(transactionId: cachedResult.id, hash: cachedResult.result.hash)
                try await pendingHashesSender.sendHash(hash)
                return mapper.mapResult(cachedResult.result, blockchain: walletModel.blockchainNetwork.blockchain)
            }

            let result = try await sendStakeKit(transaction: stakeKitTransaction)

            // Save it if `sendHash` will failed
            cachedResult = .init(id: transactionId, result: result)

            let hash = StakingPendingHash(transactionId: transactionId, hash: result.hash)
            try await pendingHashesSender.sendHash(hash)

            // Clear after success tx was successfully sent
            cachedResult = nil

            return mapper.mapResult(result, blockchain: walletModel.blockchainNetwork.blockchain)
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
}

extension StakingTransactionDispatcher {
    struct CachedResult {
        let id: String
        let result: TransactionSendResult
    }
}
