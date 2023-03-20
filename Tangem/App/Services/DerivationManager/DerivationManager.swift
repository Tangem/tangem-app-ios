//
//  DerivationManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

struct DerivationManager {
    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding

    private let config: UserWalletConfig
    private let cardInfo: CardInfo

    private var cardId: String? {
        if config.cardsCount == 1 {
            return cardInfo.card.cardId
        }

        return nil
    }

    init(config: UserWalletConfig, cardInfo: CardInfo) {
        self.config = config
        self.cardInfo = cardInfo
    }

    func deriveIfNeeded(entries: [StorageEntry], completion: @escaping (Result<DerivationResult?, TangemSdkError>) -> Void) {
        guard config.hasFeature(.hdWallets) else {
            completion(.success(nil))
            return
        }

        let nonDeriveEntries = entries.compactMap { entry -> StorageEntry? in
            guard let path = entry.blockchainNetwork.derivationPath,
                  let wallet = cardInfo.card.wallets.last(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }),
                  !wallet.derivedKeys.keys.contains(path) else {
                return nil
            }

            return entry
        }

        guard !nonDeriveEntries.isEmpty else {
            completion(.success(nil))
            return
        }

        deriveKeys(entries: nonDeriveEntries, completion: completion)
    }

    private func deriveKeys(entries: [StorageEntry], completion: @escaping (Result<DerivationResult?, TangemSdkError>) -> Void) {
        let card = cardInfo.card
        var derivations: [Data: [DerivationPath]] = [:]

        for entry in entries {
            if let path = entry.blockchainNetwork.derivationPath {
                if let wallet = card.wallets.last(where: { $0.curve == entry.blockchainNetwork.blockchain.curve }) {
                    derivations[wallet.publicKey, default: []].append(path)
                }
            }
        }

        tangemSdkProvider.sdk.startSession(with: DeriveMultipleWalletPublicKeysTask(derivations), cardId: cardId) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                AppLog.shared.error(error, params: [.action: .deriveKeys])
                completion(.failure(error))
            }
        }
    }
}

typealias DerivationResult = DeriveMultipleWalletPublicKeysTask.Response
