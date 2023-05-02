//
//  TangemSigner.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
import BlockchainSdk
import Combine

struct TangemSigner: TransactionSigner {
    var signPublisher: AnyPublisher<Card, Never> {
        _signPublisher.eraseToAnyPublisher()
    }

    private var _signPublisher: PassthroughSubject<Card, Never> = .init()
    private var initialMessage: Message { .init(header: nil, body: Localization.initialMessageSignBody) }
    private let cardId: String?
    private let twinKey: TwinKey?
    private let sdk: TangemSdk

    init(with cardId: String?, sdk: TangemSdk) {
        self.init(cardId: cardId, twinKey: nil, sdk: sdk)
    }

    init(with twinKey: TwinKey, sdk: TangemSdk) {
        self.init(cardId: nil, twinKey: twinKey, sdk: sdk)
    }

    private init(cardId: String?, twinKey: TwinKey?, sdk: TangemSdk) {
        self.cardId = cardId
        self.twinKey = twinKey
        self.sdk = sdk
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Future<[Data], Error> { promise in
            let signCommand = SignAndReadTask(
                hashes: hashes,
                walletPublicKey: walletPublicKey.seedKey,
                pairWalletPublicKey: twinKey?.getPairKey(for: walletPublicKey.seedKey),
                derivationPath: walletPublicKey.derivationPath
            )

            self.sdk.startSession(with: signCommand, cardId: self.cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self._signPublisher.send(response.card)
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }
}

struct TwinKey {
    let key1: Data
    let key2: Data

    func getPairKey(for walletPublicKey: Data) -> Data? {
        if walletPublicKey == key1 {
            return key2
        }

        if walletPublicKey == key2 {
            return key1
        }

        return nil
    }
}
