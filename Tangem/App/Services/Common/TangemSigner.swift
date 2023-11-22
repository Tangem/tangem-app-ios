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
    private let filter: CardSessionFilter
    private let twinKey: TwinKey?
    private let sdk: TangemSdk

    init(filter: CardSessionFilter, sdk: TangemSdk, twinKey: TwinKey?) {
        self.filter = filter
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

            sdk.startSession(with: signCommand, sessionFilter: filter, initialMessage: initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    _signPublisher.send(response.card)
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }

                withExtendedLifetime(signCommand) {}
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
