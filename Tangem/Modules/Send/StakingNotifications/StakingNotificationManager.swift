//
//  StakingNotificationManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingNotificationManagerInput {
    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> { get }
}

protocol StakingNotificationManager: NotificationManager {
    func setup(input: StakingNotificationManagerInput)
}

class CommonStakingNotificationManager {
    private let tokenItem: TokenItem

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var stakingManagerStateSubscription: AnyCancellable?

    private weak var delegate: NotificationTapDelegate?

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - Bind

private extension CommonStakingNotificationManager {
    func bind(input: StakingNotificationManagerInput) {
        stakingManagerStateSubscription = input
            .stakingManagerStatePublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { manager, state in
                manager.update(state: state)
            }
    }

    func update(state: StakingManagerState) {
        switch state {
        case .loading, .notEnabled:
            break
        case .availableToStake(let yield):
            show(notification: .stake(
                tokenSymbol: tokenItem.currencySymbol,
                periodFormatted: yield.rewardScheduleType.rawValue
            ))
        case .staked(_, let yield):
            show(notification: .unstake(periodFormatted: yield.rewardScheduleType.rawValue))
        }
    }
}

// MARK: - Show/Hide

private extension CommonStakingNotificationManager {
    func show(notification event: StakingNotificationEvent) {
        let input = NotificationsFactory().buildNotificationInput(for: event)
        if let index = notificationInputsSubject.value.firstIndex(where: { $0.id == input.id }) {
            notificationInputsSubject.value[index] = input
        } else {
            notificationInputsSubject.value.append(input)
        }
    }
}

// MARK: - NotificationManager

extension CommonStakingNotificationManager: StakingNotificationManager {
    func setup(input: any StakingNotificationManagerInput) {
        bind(input: input)
    }

    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {}
}
