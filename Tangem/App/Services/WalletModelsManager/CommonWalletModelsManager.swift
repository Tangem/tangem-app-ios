//
//  CommonWalletModelsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

class CommonWalletModelsManager {
    private let walletManagersRepository: WalletManagersRepository
    private let walletModelsFactory: WalletModelsFactory

    private var _walletModels = CurrentValueSubject<[WalletModel], Never>([])
    private var bag = Set<AnyCancellable>()
    private var updateAllSubscription: AnyCancellable?

    init(
        walletManagersRepository: WalletManagersRepository,
        walletModelsFactory: WalletModelsFactory
    ) {
        self.walletManagersRepository = walletManagersRepository
        self.walletModelsFactory = walletModelsFactory
        bind()
    }

    private func bind() {
        walletManagersRepository
            .walletManagersPublisher
            .sink { [weak self] managers in
                self?.updateWalletModels(with: managers)
            }
            .store(in: &bag)
    }

    private func updateWalletModels(with walletManagers: [BlockchainNetwork: WalletManager]) {
        AppLog.shared.debug("🔄 Updating Wallet models")

        var existingWalletModels = walletModels
        let newWalletModels = walletManagers.flatMap { walletModelsFactory.makeWalletModels(from: $0.value) }

        let walletModelsToDelete = Set(existingWalletModels).subtracting(newWalletModels).map { $0.id }
        let walletModelsToAdd = Set(newWalletModels).subtracting(existingWalletModels)

        guard !walletModelsToAdd.isEmpty || !walletModelsToDelete.isEmpty else {
            return
        }

        existingWalletModels.removeAll {
            walletModelsToDelete.contains($0.id)
        }

        walletModelsToAdd.forEach {
            $0.update(silent: false)
        }

        existingWalletModels.append(contentsOf: walletModelsToAdd)

        log(walletModels: existingWalletModels)

        _walletModels.send(existingWalletModels)
    }
}

// MARK: - WalletListManager

extension CommonWalletModelsManager: WalletModelsManager {
    var walletModels: [WalletModel] {
        _walletModels.value
    }

    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> {
        _walletModels.eraseToAnyPublisher()
    }

    func updateAll() {
        walletModels.forEach {
            $0.update(silent: false)
        }
    }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        let publishers = walletModels.map {
            $0.update(silent: silent)
        }

        updateAllSubscription = Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapVoid()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .receiveCompletion { _ in
                completion()
            }
    }
}

private extension CommonWalletModelsManager {
    func log(walletModels: [WalletModel]) {
        let printList = walletModels.map {
            return "\($0.name)"
        }

        AppLog.shared.debug("✅ Actual List of WalletModels [\(printList.joined(separator: ", "))]")
    }
}
