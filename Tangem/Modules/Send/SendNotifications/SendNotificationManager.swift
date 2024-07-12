//
//  SendNotificationManager.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol SendNotificationManagerInput {
    var feeValues: AnyPublisher<[SendFee], Never> { get }
    var selectedFeePublisher: AnyPublisher<SendFee?, Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    var transactionPublisher: AnyPublisher<BSDKTransaction?, Never> { get }
    var transactionCreationError: AnyPublisher<Error?, Never> { get }
}

protocol SendNotificationManager: NotificationManager {
    func setup(input: SendNotificationManagerInput)
}

class CommonSendNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let withdrawalNotificationProvider: WithdrawalNotificationProvider?

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: NotificationTapDelegate?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        withdrawalNotificationProvider: WithdrawalNotificationProvider?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.withdrawalNotificationProvider = withdrawalNotificationProvider
    }
}

// MARK: - Bind

private extension CommonSendNotificationManager {
    func bind(input: SendNotificationManagerInput) {
        input.feeValues
            .withWeakCaptureOf(self)
            .sink { manager, feeValues in
                let hasError = feeValues.contains { $0.value.error != nil }
                manager.updateNetworkFeeUnreachable(isVisible: hasError)
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            input.selectedFeePublisher.compactMap { $0 },
            input.feeValues.filter { !$0.allConforms { $0.value.isLoading } }
        )
        .sink { [weak self] selectedFee, loadedFeeValues in
            self?.updateCustomFee(selectedFee: selectedFee, feeValues: loadedFeeValues)
        }
        .store(in: &bag)

        Publishers.CombineLatest(
            input.isFeeIncludedPublisher,
            input.selectedFeePublisher.compactMap { $0?.value.value?.amount.value }
        )
        .sink { [weak self] isFeeIncluded, feeValue in
            self?.updateFeeInclusionEvent(isFeeIncluded: isFeeIncluded, feeCryptoValue: feeValue)
        }
        .store(in: &bag)

        input.transactionCreationError
            .withWeakCaptureOf(self)
            .sink { manager, error in
                manager.updateNotification(error: error)
            }
            .store(in: &bag)

        if let withdrawalNotificationProvider {
            input
                .transactionPublisher
                .withWeakCaptureOf(self)
                .map { manager, transaction in
                    transaction.flatMap {
                        withdrawalNotificationProvider.withdrawalNotification(amount: $0.amount, fee: $0.fee)
                    }
                }
                .withWeakCaptureOf(self)
                .sink { manager, notification in
                    manager.updateWithdrawalNotification(notification: notification)
                }
                .store(in: &bag)
        }
    }
}

// MARK: - Fee

private extension CommonSendNotificationManager {
    func updateNetworkFeeUnreachable(isVisible: Bool) {
        if isVisible {
            show(notification: .networkFeeUnreachable)
        } else {
            hideAllNotification { event in
                if case .networkFeeUnreachable = event {
                    return true
                }

                return false
            }
        }
    }

    func updateCustomFee(selectedFee: SendFee, feeValues: [SendFee]) {
        switch (selectedFee.option, selectedFee.value) {
        case (.custom, .loaded(let customFee)):
            updateCustomFeeTooLow(
                customFee: customFee,
                lowestFee: feeValues.first(where: { $0.option == .slow })?.value.value
            )

            updateCustomFeeTooHigh(
                customFee: customFee,
                highestFee: feeValues.first(where: { $0.option == .fast })?.value.value
            )

        default:
            hideAllNotification { event in
                switch event {
                case .customFeeTooLow, .customFeeTooHigh:
                    return true
                default:
                    return false
                }
            }
        }
    }

    func updateCustomFeeTooLow(customFee: Fee, lowestFee: Fee?) {
        if let lowestFee, customFee.amount.value < lowestFee.amount.value {
            show(notification: .customFeeTooLow)
        } else {
            hideAllNotification { event in
                if case .customFeeTooLow = event {
                    return true
                }

                return false
            }
        }
    }

    func updateCustomFeeTooHigh(customFee: Fee, highestFee: Fee?) {
        let magnitudeTrigger: Decimal = 5

        if let highestFee, customFee.amount.value > highestFee.amount.value * magnitudeTrigger {
            let highFeeOrder = customFee.amount.value / highestFee.amount.value
            let highFeeOrderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)

            show(notification: .customFeeTooHigh(orderOfMagnitude: highFeeOrderOfMagnitude))
        } else {
            hideAllNotification { event in
                if case .customFeeTooHigh = event {
                    return true
                }

                return false
            }
        }
    }

    func updateFeeInclusionEvent(isFeeIncluded: Bool, feeCryptoValue: Decimal) {
        if isFeeIncluded {
            let feeFiatValue = feeTokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(feeCryptoValue, currencyId: $0) }

            let formatter = BalanceFormatter()
            let cryptoAmountFormatted = formatter.formatCryptoBalance(feeCryptoValue, currencyCode: feeTokenItem.currencySymbol)
            let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

            show(notification: .feeWillBeSubtractFromSendingAmount(
                cryptoAmountFormatted: cryptoAmountFormatted,
                fiatAmountFormatted: fiatAmountFormatted
            ))
        } else {
            hideAllNotification { event in
                if case .feeWillBeSubtractFromSendingAmount = event {
                    return true
                }

                return false
            }
        }
    }
}

// MARK: - ValidationError

private extension CommonSendNotificationManager {
    func updateWithdrawalNotification(notification: WithdrawalNotification?) {
        switch notification {
        case .none:
            hideAllNotification { event in
                if case .withdrawalNotificationEvent = event {
                    return true
                }

                return false
            }
        case .some(let suggestion):
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(suggestion)
            show(notification: .withdrawalNotificationEvent(withdrawalNotification))
        }
    }

    func updateNotification(error: Error?) {
        switch error {
        case .none:
            hideAllValidationErrorEvent()
        case let validationError as ValidationError:
            let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
            let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)

            switch validationErrorEvent {
            case .dustRestriction,
                 .insufficientBalance,
                 .insufficientBalanceForFee,
                 .existentialDeposit,
                 .amountExceedMaximumUTXO,
                 .cardanoCannotBeSentBecauseHasTokens,
                 .cardanoInsufficientBalanceToSendToken,
                 .notEnoughMana,
                 .manaLimit,
                 .koinosInsufficientBalanceToSendKoin,
                 .insufficientAmountToReserveAtDestination:
                show(notification: .validationErrorEvent(validationErrorEvent))
            case .invalidNumber:
                hideAllValidationErrorEvent()
            }
        default:
            AppLog.shared.debug("Transaction error will not show to user")
            hideAllValidationErrorEvent()
        }
    }
}

// MARK: - Show/Hide

private extension CommonSendNotificationManager {
    func show(notification event: SendNotificationEvent) {
        let input = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        } dismissAction: { [weak self] id in
            self?.notificationInputsSubject.value.removeAll {
                $0.settings.id == id
            }
        }

        notificationInputsSubject.value.appendIfNotContains(input)
    }

    func hideAllValidationErrorEvent() {
        hideAllNotification { event in
            if case .validationErrorEvent = event {
                return true
            }

            return false
        }
    }

    func hideAllNotification(where shouldBeRemoved: (SendNotificationEvent) -> Bool) {
        notificationInputsSubject.value.removeAll(where: { input in
            guard let event = input.settings.event as? SendNotificationEvent else {
                return false
            }

            return shouldBeRemoved(event)
        })
    }
}

// MARK: - SendNotificationManager

extension CommonSendNotificationManager: SendNotificationManager {
    func setup(input: SendNotificationManagerInput) {
        bag.removeAll()

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
