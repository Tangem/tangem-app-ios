//
//  CommonWalletModelsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import BlockchainSdk

class CommonWalletModelsManager {
    private let walletManagersRepository: WalletManagersRepository
    private let walletModelsFactory: WalletModelsFactory

    /// We need to keep optional array to track state when wallet models array wasn't able to initialize
    /// This state can happen while app awaiting API list from server, because and Wallet managers can't be created without this info
    /// Nil state is not the same as an empty state, because user can remove all tokens from main and the array will be empty
    /// Also if we initialize CurrentValueSubject with empty array recipients will evaluate this state as an empty list
    private var _walletModels = CurrentValueSubject<[WalletModel]?, Never>(nil)
    private var bag = Set<AnyCancellable>()
    private var updateAllSubscription: AnyCancellable?

    /// An update is tracked only once per lifecycle of this manager.
    private var shouldTrackWalletModelsUpdate = true

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

        let existingWalletModelIds = Set(walletModels.map { $0.walletModelId })

        let newWalletModelIds = Set(walletManagers.flatMap { network, walletManager in
            let mainId = WalletModel.Id(tokenItem: .blockchain(network))
            let tokenIds = walletManager.cardTokens.map { WalletModel.Id(tokenItem: .token($0, network)) }
            return [mainId] + tokenIds
        })

        let walletModelIdsToDelete = existingWalletModelIds.subtracting(newWalletModelIds)
        let walletModelIdsToAdd = newWalletModelIds.subtracting(existingWalletModelIds)

        if walletModelIdsToAdd.isEmpty, walletModelIdsToDelete.isEmpty {
            if _walletModels.value == nil {
                // Emit initial list. Case with first card scan without derivations
                _walletModels.send([])
            }

            return
        }

        var existingWalletModels = walletModels

        existingWalletModels.removeAll {
            walletModelIdsToDelete.contains($0.walletModelId)
        }

        let dataToAdd = Dictionary(grouping: walletModelIdsToAdd, by: { $0.tokenItem.blockchainNetwork })

        let walletModelsToAdd: [WalletModel] = dataToAdd.flatMap {
            if let walletManager = walletManagers[$0.key] {
                let types = $0.value.map { $0.tokenItem.amountType }
                return walletModelsFactory.makeWalletModels(for: types, walletManager: walletManager)
            }

            return []
        }

        updateWalletModelsWithPerformanceTrackingIfNeeded(walletModels: walletModelsToAdd)

        existingWalletModels.append(contentsOf: walletModelsToAdd)

        log(walletModels: existingWalletModels)

        _walletModels.send(existingWalletModels)
    }

    private func updateWalletModelsWithPerformanceTrackingIfNeeded(walletModels: [WalletModel]) {
        var token: PerformanceMetricToken?

        if shouldTrackWalletModelsUpdate, walletModels.isNotEmpty {
            shouldTrackWalletModelsUpdate = false
            token = PerformanceTracker.startTracking(metric: .totalBalanceLoaded(tokensCount: walletModels.count))
        }

        var subscription: AnyCancellable?
        subscription = walletModels
            .map { $0.update(silent: false) }
            .combineLatest()
            .sink { states in
                if states.contains(where: \.isBlockchainUnreachable) {
                    PerformanceTracker.endTracking(token: token, with: .failure)
                } else {
                    PerformanceTracker.endTracking(token: token, with: .success)
                }
                withExtendedLifetime(subscription) {}
            }
    }
}

// MARK: - WalletListManager

extension CommonWalletModelsManager: WalletModelsManager {
    var walletModels: [WalletModel] {
        _walletModels.value ?? []
    }

    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> {
        _walletModels
            .compactMap { $0 }
            .eraseToAnyPublisher()
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
            .mapToVoid()
            .receive(on: DispatchQueue.main)
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
