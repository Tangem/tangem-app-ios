//
//  MultiWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 06/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MultiWalletNotificationManager {
    private let analyticsService = NotificationsAnalyticsService()
    private let walletModelsManager: WalletModelsManager

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var updateSubscription: AnyCancellable?

    init(walletModelsManager: WalletModelsManager, contextDataProvider: AnalyticsContextDataProvider?) {
        self.walletModelsManager = walletModelsManager

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
        bind()
    }

    private func bind() {
        updateSubscription = walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .flatMap { walletModels in
                let coinsOnlyModels = walletModels.filter { !$0.tokenItem.isToken }
                return Publishers.MergeMany(coinsOnlyModels.map { $0.walletDidChangePublisher })
                    .map { _ in coinsOnlyModels }
                    .filter { walletModels in
                        walletModels.allConforms { !$0.state.isLoading }
                    }
            }
            .sink { [weak self] walletModels in
                let unreachableNetworks = walletModels.filter {
                    if case .binance = $0.blockchainNetwork.blockchain {
                        return false
                    }

                    return $0.state.isBlockchainUnreachable
                }

                guard !unreachableNetworks.isEmpty else {
                    self?.show(event: .none)
                    return
                }

                self?.show(event: .someNetworksUnreachable(
                    currencySymbols: unreachableNetworks.map(\.tokenItem.currencySymbol)
                ))
            }
    }

    private func show(event: MultiWalletNotificationEvent?) {
        let input = event.map { NotificationsFactory().buildNotificationInput(for: $0) }
        notificationInputsSubject.value = input.map { [$0] } ?? []
    }
}

extension MultiWalletNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
