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
    private let feeTokenItem: TokenItem

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var stateSubscription: AnyCancellable?

    private lazy var daysFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day]
        return formatter
    }()

    private weak var delegate: NotificationTapDelegate?

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - Bind

private extension CommonStakingNotificationManager {
    func update(state: StakingModel.State, yield: YieldInfo) {
        switch state {
        case .loading:
            break
        case .approveTransactionInProgress:
            show(notification: .approveTransactionInProgress)
        case .readyToApprove:
            show(notification: .stake(
                tokenSymbol: tokenItem.currencySymbol,
                rewardScheduleType: yield.rewardScheduleType
            ))
        case .readyToStake(let readyToStake):
            var events: [StakingNotificationEvent] = [
                .stake(
                    tokenSymbol: tokenItem.currencySymbol,
                    rewardScheduleType: yield.rewardScheduleType
                ),
            ]

            if readyToStake.isFeeIncluded {
                let feeFiatValue = feeTokenItem.currencyId.flatMap {
                    BalanceConverter().convertToFiat(readyToStake.fee, currencyId: $0)
                }

                let formatter = BalanceFormatter()
                let cryptoAmountFormatted = formatter.formatCryptoBalance(readyToStake.fee, currencyCode: feeTokenItem.currencySymbol)
                let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

                events.append(
                    .feeWillBeSubtractFromSendingAmount(
                        cryptoAmountFormatted: cryptoAmountFormatted,
                        fiatAmountFormatted: fiatAmountFormatted
                    )
                )
            }

            show(events: events)

        case .validationError(let validationError, _):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            show(notification: .validationErrorEvent(validationErrorEvent))
        case .networkError:
            show(notification: .networkUnreachable)
        }
    }

    func update(state: UnstakingModel.State, yield: YieldInfo, action: UnstakingModel.Action) {
        switch state {
        case .loading, .ready:
            show(notification: .unstake(
                periodFormatted: yield.unbondingPeriod.formatted(formatter: daysFormatter)
            ))
        case .validationError(let validationError, _):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            show(notification: .validationErrorEvent(validationErrorEvent))
        case .networkError:
            show(notification: .networkUnreachable)
        }
    }
}

// MARK: - Show/Hide

private extension CommonStakingNotificationManager {
    func show(notification: StakingNotificationEvent) {
        show(events: [notification])
    }

    func show(events: [StakingNotificationEvent]) {
        let factory = NotificationsFactory()

        notificationInputsSubject.value = events.map { event in
            factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                self?.delegate?.didTapNotification(with: id, action: actionType)
            }
        }
    }
}

// MARK: - NotificationManager

extension CommonStakingNotificationManager: StakingNotificationManager {
    func setup(provider: StakingModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.state,
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, yield: state.1)
        }
    }

    func setup(provider: UnstakingModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.statePublisher,
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, yield: state.1, action: provider.stakingAction)
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
