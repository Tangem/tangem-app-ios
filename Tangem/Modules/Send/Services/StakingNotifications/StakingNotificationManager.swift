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
    func setup(provider: RestakingModelStateProvider, input: StakingNotificationManagerInput)
    func setup(provider: StakingSingleActionModelStateProvider, input: StakingNotificationManagerInput)
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
            hideErrorNotifications()
        case .approveTransactionInProgress:
            show(notification: .approveTransactionInProgress)
            hideErrorNotifications()
        case .readyToApprove:
            hideApproveInProgressNotification()
            hideErrorNotifications()
        case .readyToStake(let readyToStake):
            var events: [StakingNotificationEvent] = []

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

                events.append(.maxAmountStaking)
            }

            if !tokenItem.supportsStakingOnDifferentValidators, readyToStake.stakeOnDifferentValidator {
                events.append(.stakesWillMoveToNewValidator(blockchain: tokenItem.blockchain.displayName))
            }

            show(events: events)
            hideErrorNotifications()

        case .validationError(let validationError, _):
            hideApproveInProgressNotification()
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)
            if case .remainingAmountIsLessThanRentExtemption = validationError {
                hideAmountRelatedNotifications()
            }
            show(error: .validationErrorEvent(validationErrorEvent))
        case .networkError:
            hideApproveInProgressNotification()
            show(error: .networkUnreachable)
        }
    }

    func update(state: UnstakingModel.State, yield: YieldInfo, action: UnstakingModel.Action, stakedBalance: Decimal) {
        switch (state, action.type) {
        case (.loading, .pending(.withdraw)), (.ready, .pending(.withdraw)),
             (.loading, .pending(.claimUnstaked)), (.ready, .pending(.claimUnstaked)):
            show(notification: .withdraw)
            hideErrorNotifications()
        case (.loading, .pending(.claimRewards)), (.ready, .pending(.claimRewards)):
            show(notification: .claimRewards)
            hideErrorNotifications()
        case (.loading, .pending(.restakeRewards)), (.ready, .pending(.restakeRewards)):
            show(notification: .restakeRewards)
            hideErrorNotifications()
        case (.loading, .pending(.unlockLocked)), (.ready, .pending(.unlockLocked)):
            show(notification: .unlock(
                periodFormatted: yield.unbondingPeriod.formatted(formatter: daysFormatter)
            ))
            hideErrorNotifications()
        case (.loading, _), (.ready, _):
            let description: String = {
                switch tokenItem.blockchain {
                case .cosmos:
                    return Localization.stakingNotificationUnstakeCosmosText
                default:
                    return Localization.stakingNotificationUnstakeText(
                        yield.unbondingPeriod.formatted(formatter: daysFormatter)
                    )
                }
            }()
            let unstakeNotificationEvent: StakingNotificationEvent = .unstake(description: description)

            let remainingAmount = stakedBalance - action.amount
            if remainingAmount > 0, remainingAmount < yield.exitMinimumRequirement {
                show(events: [unstakeNotificationEvent, .lowStakedBalance])
            } else {
                show(notification: unstakeNotificationEvent)
            }
            hideErrorNotifications()
        case (.validationError(let validationError, _), _):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            show(error: .validationErrorEvent(validationErrorEvent))
        case (.networkError, _):
            show(error: .networkUnreachable)
        }
    }

    func update(state: RestakingModel.State, action: RestakingModel.Action) {
        switch state {
        case .loading, .ready:
            switch tokenItem.blockchain {
            case .tron:
                show(notification: .revote)
            default:
                break
            }

            if case .cardano = tokenItem.blockchain, case .stake = action.type {
                show(notification: .cardanoAdditionalDeposit)
            }

            if case .pending(.restake) = action.type {
                show(notification: .restake)
            }

            hideErrorNotifications()
        case .networkError:
            show(error: .networkUnreachable)
        case .validationError(let validationError, _):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            show(error: .validationErrorEvent(validationErrorEvent))
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

    func show(error event: StakingNotificationEvent) {
        let input = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        notificationInputsSubject.value.append(input)
    }

    func hideErrorNotifications() {
        notificationInputsSubject.value.removeAll { input in
            switch input.settings.event {
            case StakingNotificationEvent.validationErrorEvent, StakingNotificationEvent.networkUnreachable:
                return true
            default:
                return false
            }
        }
    }

    func hideApproveInProgressNotification() {
        notificationInputsSubject.value.removeAll { input in
            switch input.settings.event {
            case StakingNotificationEvent.approveTransactionInProgress: true
            default: false
            }
        }
    }

    func hideAmountRelatedNotifications() {
        notificationInputsSubject.value.removeAll { input in
            switch input.settings.event {
            case StakingNotificationEvent.maxAmountStaking,
                 StakingNotificationEvent.feeWillBeSubtractFromSendingAmount:
                true
            default: false
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
            manager.update(
                state: state.0,
                yield: state.1,
                action: provider.stakingAction,
                stakedBalance: provider.stakedBalance
            )
        }
    }

    func setup(provider: RestakingModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.statePublisher,
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, action: provider.stakingAction)
        }
    }

    func setup(provider: StakingSingleActionModelStateProvider, input: StakingNotificationManagerInput) {
        stateSubscription = Publishers.CombineLatest(
            provider.statePublisher,
            input.stakingManagerStatePublisher.compactMap { $0.yieldInfo }.removeDuplicates()
        )
        .withWeakCaptureOf(self)
        .sink { manager, state in
            manager.update(state: state.0, yield: state.1, action: provider.stakingAction, stakedBalance: provider.stakingAction.amount)
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

private extension TokenItem {
    var supportsStakingOnDifferentValidators: Bool {
        switch blockchain {
        case .tron: false
        default: true
        }
    }
}
