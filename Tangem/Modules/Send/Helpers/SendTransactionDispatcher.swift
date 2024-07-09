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

protocol SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { get }

    func send(transaction: BlockchainSdk.Transaction) -> AnyPublisher<SendTransactionSentResult, SendTxError>
}

struct SendTransactionSentResult {
    let url: URL?
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

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }
}

// MARK: - SendTransactionDispatcher

extension CommonSendTransactionDispatcher: SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func send(transaction: BlockchainSdk.Transaction) -> AnyPublisher<SendTransactionSentResult, SendTxError> {
        _isSending.send(true)

        return walletModel
            .send(transaction, signer: transactionSigner)
            .withWeakCaptureOf(self)
            .map { sender, result in
                sender._isSending.send(false)

                return .init(url: sender.explorerUrl(from: result.hash))
            }
            .eraseToAnyPublisher()
    }
}
