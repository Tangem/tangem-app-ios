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
    func setup(provider: StakingModelStateProvider, input: StakingNotificationManagerInput)
    func setup(provider: UnstakingModelStateProvider, input: StakingNotificationManagerInput)
}

class CommonStakingNotificationManager {
    private let tokenItem: TokenItem

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var stateSubscription: AnyCancellable?

    private lazy var daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    private weak var delegate: NotificationTapDelegate?

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - Bind

private extension CommonStakingNotificationManager {
    func update(state: StakingModel.State, yield: YieldInfo) {
        switch state {
        case .approveTransactionInProgress:
            show(notification: .approveTransactionInProgress)
        case .readyToApprove, .readyToStake:
            show(notification: .stake(
                tokenSymbol: tokenItem.currencySymbol,
                rewardScheduleType: yield.rewardScheduleType
            ))
        }
    }

    func update(state: UnstakingModel.State, yield: YieldInfo) {
        switch state {
        case .unstaking, .withdraw:
            show(notification: .unstake(
                periodFormatted: yield.unbondingPeriod.formatted(formatter: daysFormatter)
            ))
        }
    }
}

// MARK: - Show/Hide

private extension CommonStakingNotificationManager {
    func show(notification event: StakingNotificationEvent) {
        let input = NotificationsFactory().buildNotificationInput(for: event)
        notificationInputsSubject.value = [input]
    }
}

// MARK: - NotificationManager

extension CommonStakingNotificationManager: StakingNotificationManager {
    func setup(provider: StakingModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.state.removeDuplicates(),
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, yield: state.1)
        }
    }

    func setup(provider: UnstakingModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.state.removeDuplicates(),
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, yield: state.1)
        }
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
