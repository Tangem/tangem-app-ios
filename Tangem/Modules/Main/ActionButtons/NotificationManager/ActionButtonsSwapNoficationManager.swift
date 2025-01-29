//
//  ActionButtonsSwapNoficationManager.swift
//  TangemApp
//
//  Created by GuitarKitty on 29.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

enum ActionButtonsNotificationDestination {
    case swap(AnyPublisher<ActionButtonsSwapViewModel.ActionButtonsTokenSelectorState, Never>)
    case sell(AnyPublisher<ActionButtonsSellViewModel.SellTokensListState, Never>)
}

final class ActionButtonsNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private let destination: ActionButtonsNotificationDestination

    private weak var delegate: NotificationTapDelegate?

    private var bag = Set<AnyCancellable>()

    init(
        destination: ActionButtonsNotificationDestination
    ) {
        self.destination = destination
        bind(to: destination)
    }

    func bind(to destination: ActionButtonsNotificationDestination) {
        switch destination {
        case .swap(let swapStatePublisher):
            swapStatePublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: weakify(
                    self,
                    forFunction: ActionButtonsNotificationManager.setupSwapNotifications(for:)
                ))
                .store(in: &bag)
        case .sell(let sellStatePubliser):
            sellStatePubliser
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: weakify(
                    self,
                    forFunction: ActionButtonsNotificationManager.setupSellNotifications(for:)
                ))
                .store(in: &bag)
        }
    }

    private func makeNotification(with event: ActionButtonsNotificationEvent) {
        let notificationsFactory = NotificationsFactory()

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }
}

// MARK: - Sell

private extension ActionButtonsNotificationManager {
    func setupSellNotifications(
        for state: ActionButtonsSellViewModel.SellTokensListState
    ) {
        switch state {
        case .regionalRestrictions:
            makeNotification(with: .sellRegionalRestriction)
        case .idle:
            notificationInputsSubject.value = []
        }
    }
}

// MARK: - Swap

private extension ActionButtonsNotificationManager {
    func setupSwapNotifications(
        for state: ActionButtonsSwapViewModel.ActionButtonsTokenSelectorState
    ) {
        switch state {
        case .refreshRequired(let title, let message):
            makeNotification(
                with: .refreshRequired(
                    title: title,
                    message: message
                )
            )
        case .noAvailablePairs:
            makeNotification(with: .noAvailablePairs)
        case .loaded, .loading, .initial, .readyToSwap:
            notificationInputsSubject.value = []
        }
    }
}

extension ActionButtonsNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        switch destination {
        case .sell:
            setupSellNotifications(for: .idle)
        case .swap:
            setupSwapNotifications(for: .loaded)
        }
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
