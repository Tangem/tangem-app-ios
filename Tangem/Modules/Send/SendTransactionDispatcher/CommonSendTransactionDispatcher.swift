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
    private let transactionSigner: TangemSigner

    init(
        walletModel: WalletModel,
        transactionSigner: TangemSigner
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }
}

// MARK: - SendTransactionDispatcher

extension CommonSendTransactionDispatcher: SendTransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .transfer(let transferTransaction) = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = SendTransactionMapper()

        do {
            let hash = try await walletModel.transactionSender.send(transferTransaction, signer: transactionSigner).async()
            walletModel.updateAfterSendingTransaction()
            let signer = transactionSigner.latestSigner.value
            return mapper.mapResult(hash, blockchain: walletModel.blockchainNetwork.blockchain, signer: signer)
        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}
