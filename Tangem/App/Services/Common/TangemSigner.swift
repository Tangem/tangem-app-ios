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
        latestSigner
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private(set) var latestSigner: CurrentValueSubject<Card?, Never> = .init(nil)
    private var initialMessage: Message { .init(header: nil, body: Localization.initialMessageSignBody) }
    private let filter: SessionFilter
    private let twinKey: TwinKey?
    private let sdk: TangemSdk

    init(filter: SessionFilter, sdk: TangemSdk, twinKey: TwinKey?) {
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
                derivationPath: walletPublicKey.signDerivationPath
            )

            sdk.startSession(with: signCommand, filter: filter, initialMessage: initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    latestSigner.send(response.card)
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
