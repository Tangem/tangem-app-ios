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

    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .transfer(let transferTransaction) = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        _isSending.send(true)
        defer {
            _isSending.send(false)
        }

        let mapper = SendTransactionMapper()

        do {
            let hash = try await walletModel.transactionSender.send(transferTransaction, signer: transactionSigner).async()
            walletModel.updateAfterSendingTransaction()
            return mapper.mapResult(hash, blockchain: walletModel.blockchainNetwork.blockchain)
        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}
