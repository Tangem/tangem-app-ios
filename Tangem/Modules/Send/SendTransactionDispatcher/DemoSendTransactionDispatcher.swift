//
//  DemoSendTransactionDispatcher.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class DemoSendTransactionDispatcher {
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

extension DemoSendTransactionDispatcher: SendTransactionDispatcher {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func sendPublisher(transaction: SendTransactionType) -> AnyPublisher<SendTransactionDispatcherResult, Never> {
        guard case .transfer = transaction else {
            return .just(output: .transactionNotFound)
        }

        _isSending.send(true)

        let hash = Data.randomData(count: 32)

        return transactionSigner
            .sign(hash: hash, walletPublicKey: walletModel.wallet.publicKey)
            .mapSendError(tx: hash.hexString)
            .eraseSendError()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?._isSending.send(false)
            })
            .map { _ in .demoAlert }
            .catch { SendTransactionMapper().mapError($0, transaction: transaction) }
            .eraseToAnyPublisher()
    }

    func send(transaction: SendTransactionType) async throws -> String {
        let _ = try await sendPublisher(transaction: transaction).async()
        return ""
    }
}
