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

    init(keysRepository: KeysRepository, userTokenListManager: UserTokenListManager) {
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

            let derivationPaths = entry.blockchainNetwork.derivationPaths()
            guard let masterKey = keys.first(where: { $0.curve == curve }) else {
                return
            }

            let pendingDerivationPaths = derivationPaths.filter { derivationPath in
                !masterKey.derivedKeys.keys.contains { $0 == derivationPath }
            }

            if pendingDerivationPaths.isEmpty {
                return
            }

            derivations[masterKey.publicKey, default: []] += pendingDerivationPaths
        }

        pendingDerivations.send(derivations)
    }
}

extension CommonDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivations
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivations
            .map { pending in
                pending.reduce(0) { $0 + $1.value.count }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func deriveKeys(cardInteractor: KeysDeriving, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
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

                // delay to get more time to updaеe ui and hide generate addresses shit under thе hood
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(cardInteractor) {}
        }
    }
}
