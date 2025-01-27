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
    private let totalBalanceProvider: TotalBalanceProviding

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var updateSubscription: AnyCancellable?

    init(totalBalanceProvider: TotalBalanceProviding, contextDataProvider: AnalyticsContextDataProvider?) {
        self.totalBalanceProvider = totalBalanceProvider

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
        bind()
    }

    private func bind() {
        updateSubscription = totalBalanceProvider
            .totalBalancePublisher
            .withWeakCaptureOf(self)
            .sink { manager, state in
                manager.setup(state: state)
            }
    }

    private func setup(state: TotalBalanceState) {
        switch state {
        case .empty, .loading:
            break
        case .failed(cached: .some, _):
            show(event: .someTokenBalancesNotUpdated)
        case .failed(cached: .none, let unreachableNetworks):
            show(event: .someNetworksUnreachable(currencySymbols: unreachableNetworks.map(\.currencySymbol)))
        case .loaded:
            show(event: .none)
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
