//
//  SimpleTransactionSigner.swift
//  BlockchainSdkExample
//
//  Created by Andrey Fedorov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

@available(iOS 13.0, *)
class CommonSigner {
    var cardId: String?
    var initialMessage: Message?

    private let sdk: TangemSdk

    init(sdk: TangemSdk, cardId: String? = nil, initialMessage: Message? = nil) {
        self.sdk = sdk
        self.cardId = cardId
        self.initialMessage = initialMessage
    }
}

// MARK: - TransactionSigner protocol conformance

extension CommonSigner: TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                return sdk.sign(
                    hashes: hashes,
                    walletPublicKey: walletPublicKey.seedKey,
                    cardId: cardId,
                    derivationPath: walletPublicKey.derivationPath,
                    initialMessage: initialMessage
                ) { signResult in
                    switch signResult {
                    case .success(let response):
                        promise(.success(response.signatures))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0.first ?? Data() }
            .eraseToAnyPublisher()
    }

    func sign(dataToSign: [BlockchainSdk.SignData], seedKey: Data) -> AnyPublisher<[(Data, Data)], any Error> {
        Fail(error: WalletError.empty).eraseToAnyPublisher()
    }
}
