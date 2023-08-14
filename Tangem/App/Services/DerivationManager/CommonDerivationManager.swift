//
//  DerivationManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk
import Combine
import BlockchainSdk

class CommonDerivationManager {
    weak var delegate: DerivationManagerDelegate?

    private let keysRepository: KeysRepository
    private let userTokenListManager: UserTokenListManager

    private var bag = Set<AnyCancellable>()
    private let pendingDerivations: CurrentValueSubject<[Data: [DerivationPath]], Never> = .init([:])

    internal init(keysRepository: KeysRepository, userTokenListManager: UserTokenListManager) {
        self.keysRepository = keysRepository
        self.userTokenListManager = userTokenListManager
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .sink { [weak self] entries, keys in
                self?.process(entries, keys)
            }
            .store(in: &bag)
    }

    private func process(_ entries: [StorageEntry], _ keys: [CardDTO.Wallet]) {
        var derivations: [Data: [DerivationPath]] = [:]

        entries.forEach { entry in
            let curve = entry.blockchainNetwork.blockchain.curve

            let derivationPaths = derivationPaths(from: entry.blockchainNetwork)
            guard let masterKey = keys.first(where: { $0.curve == curve }) else {
                return
            }

            // If needed derivationPaths already add just skip it
            if derivationPaths.allConforms(masterKey.derivedKeys.keys.contains(_:)) {
                return
            }

            derivations[masterKey.publicKey, default: []] += derivationPaths
        }

        pendingDerivations.send(derivations)
    }

    private func derivationPaths(from network: BlockchainNetwork) -> [DerivationPath] {
        guard let derivationPath = network.derivationPath else {
            return []
        }

        // If we use the extended cardano then
        // we should have two derivations for collect correct PublicKey
        guard case .cardano(let extended) = network.blockchain, extended else {
            return [derivationPath]
        }

        do {
            let extendedPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)
            return [derivationPath, extendedPath]
        } catch {
            AppLog.shared.error(error)
            return [derivationPath]
        }
    }
}

extension CommonDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivations
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func deriveKeys(cardInteractor: CardDerivable, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard !pendingDerivations.value.isEmpty else {
            completion(.success(()))
            return
        }

        cardInteractor.deriveKeys(derivations: pendingDerivations.value) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                var keys = keysRepository.keys
                for updatedWallet in response {
                    for derivedKey in updatedWallet.value.keys {
                        keys[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                    }
                }

                // TODO: refactor storage to single source
                keysRepository.update(keys: keys)
                delegate?.onDerived(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(cardInteractor) {}
        }
    }
}
