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
    var selectedSendFeePublisher: AnyPublisher<SendFee?, Never> { get }
    var feeValues: AnyPublisher<[SendFee], Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> { get }
    var amountError: AnyPublisher<Error?, Never> { get }
    var transactionCreationError: AnyPublisher<Error?, Never> { get }
}

protocol SendNotificationManager: NotificationManager {
    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never>
    func hasNotifications(with severity: NotificationView.Severity) -> AnyPublisher<Bool, Never>

    func setup(input: SendNotificationManagerInput)
}

class CommonSendNotificationManager: SendNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private let validationErrorInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []

    private var notEnoughFeeConfiguration: TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration {
        TransactionSendAvailabilityProvider.SendingRestrictions.NotEnoughFeeConfiguration(
            transactionAmountTypeName: tokenItem.name,
            feeAmountTypeName: feeTokenItem.name,
            feeAmountTypeCurrencySymbol: feeTokenItem.currencySymbol,
            feeAmountTypeIconName: feeTokenItem.blockchain.iconNameFilled,
            networkName: tokenItem.networkName,
            currencyButtonTitle: nil
        )
    }

    private weak var delegate: NotificationTapDelegate?

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never> {
        notificationPublisher
            .map {
                $0.filter { input in
                    guard let sendNotificationEvent = input.settings.event as? SendNotificationEvent else {
                        return false
                    }

                    return sendNotificationEvent.locations.contains(location)
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func hasNotifications(with severity: NotificationView.Severity) -> AnyPublisher<Bool, Never> {
        notificationPublisher
            .map { notificationInputs in
                notificationInputs.contains { $0.settings.event.severity == severity }
            }
            .eraseToAnyPublisher()
    }

    func hasNotificationEvent(_ event: SendNotificationEvent) -> Bool {
        return notificationInputs.contains { notificationInput in
            notificationInput.settings.event.id == event.id
        }
    }

    func setup(input: SendNotificationManagerInput) {
        input
            .feeValues
            .map {
                $0.contains { $0.value.error != nil }
            }
            .sink { [weak self] hasError in
                self?.updateEventVisibility(hasError, event: .networkFeeUnreachable)
            }
            .store(in: &bag)

        input
            .withdrawalNotification
            .sink { [weak self] withdrawalNotification in
                guard let self else { return }

                switch withdrawalNotification {
                case .some(let suggestion):
                    let factory = BlockchainSDKNotificationMapper(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
                    let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(suggestion)
                    updateEventVisibility(true, event: .withdrawalNotificationEvent(withdrawalNotification))
                case .none:
                    hideAllWithdrawalNotificationEvent()
                }
            }
            .store(in: &bag)

        let loadedFeeValues = input
            .feeValues
            .filter { !$0.allConforms { $0.value.isLoading } }

        Publishers.CombineLatest(input.selectedSendFeePublisher, loadedFeeValues)
            .sink { [weak self] selectedFee, loadedFeeValues in

                switch (selectedFee?.option, selectedFee?.value) {
                case (.custom, .loaded(let customFee)):
                    let highFeeOrderOfMagnitudeTrigger: Decimal = 5
                    var customFeeTooLow: Bool = false
                    var customFeeTooHigh: Bool = false
                    var highFeeOrderOfMagnitude: Int = 0

                    if let lowestFee = loadedFeeValues.first(where: { $0.option == .slow })?.value.value,
                       let highestFee = loadedFeeValues.first(where: { $0.option == .fast })?.value.value {
                        customFeeTooLow = customFee.amount.value < lowestFee.amount.value
                        customFeeTooHigh = customFee.amount.value > highestFee.amount.value * highFeeOrderOfMagnitudeTrigger

                        let highFeeOrder = customFee.amount.value / highestFee.amount.value
                        highFeeOrderOfMagnitude = highFeeOrder.intValue(roundingMode: .plain)
                    }

                    self?.updateEventVisibility(customFeeTooLow, event: .customFeeTooLow)
                    self?.updateEventVisibility(customFeeTooHigh, event: .customFeeTooHigh(orderOfMagnitude: highFeeOrderOfMagnitude))

                default:
                    self?.updateEventVisibility(false, event: .customFeeTooLow)
                    self?.updateEventVisibility(false, event: .customFeeTooHigh(orderOfMagnitude: 0))
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest(
            input.isFeeIncludedPublisher,
            input.selectedSendFeePublisher.map { $0?.value.value?.amount.value }
        )
        .sink { [weak self] isFeeIncluded, feeValue in
            self?.updateFeeInclusionEvent(isFeeIncluded: isFeeIncluded, feeCryptoValue: feeValue)
        }
        .store(in: &bag)

        Publishers.CombineLatest(
            input.amountError.compactMap { [$0].compactMap { $0 } },
            input.transactionCreationError.compactMap { [$0].compactMap { $0 } }
        )
        .map {
            $0.0 + $0.1
        }
        .withWeakCaptureOf(self)
        .map { (self, errors) -> [NotificationViewInput] in
            self.notificationInputs(from: errors.first)
        }
        .assign(to: \.value, on: validationErrorInputsSubject, ownership: .weak)
        .store(in: &bag)
    }

    private func updateFeeInclusionEvent(isFeeIncluded: Bool, feeCryptoValue: Decimal?) {
        let cryptoAmountFormatted: String
        let fiatAmountFormatted: String
        let visible: Bool
        if let feeCryptoValue, isFeeIncluded {
            let converter = BalanceConverter()
            let feeFiatValue = converter.convertToFiat(feeCryptoValue, currencyId: feeTokenItem.currencyId ?? "")

            let formatter = BalanceFormatter()
            cryptoAmountFormatted = formatter.formatCryptoBalance(feeCryptoValue, currencyCode: feeTokenItem.currencySymbol)
            fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

            visible = true
        } else {
            cryptoAmountFormatted = ""
            fiatAmountFormatted = ""
            visible = false
        }

        let event = SendNotificationEvent.feeWillBeSubtractFromSendingAmount(
            cryptoAmountFormatted: cryptoAmountFormatted,
            fiatAmountFormatted: fiatAmountFormatted
        )

        updateEventVisibility(visible, event: event)
    }

    private func notificationInputs(from error: Error?) -> [NotificationViewInput] {
        guard let validationError = error as? ValidationError else { return [] }

        let factory = NotificationsFactory()

        guard let event = notificationEvent(from: validationError) else { return [] }

        let input = factory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        } dismissAction: { [weak self] id in
            self?.dismissAction(with: id)
        }
        return [input]
    }

    private func dismissAction(with settingsId: NotificationViewId) {
        notificationInputsSubject.value.removeAll {
            $0.settings.id == settingsId
        }
    }

    private func hideAllWithdrawalNotificationEvent() {
        notificationInputsSubject.value.removeAll(where: { input in
            guard case .withdrawalNotificationEvent = input.settings.event as? SendNotificationEvent else {
                return false
            }

            return true
        })
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if visible {
            let factory = NotificationsFactory()
            let input = factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                self?.delegate?.didTapNotification(with: id, action: actionType)
            } dismissAction: { [weak self] id in
                self?.dismissAction(with: id)
            }

            if let index = notificationInputsSubject.value.firstIndex(where: { $0.settings.event.id == event.id }) {
                notificationInputsSubject.value[index] = input
            } else {
                notificationInputsSubject.value.append(input)
            }
        } else {
            notificationInputsSubject.value.removeAll { $0.settings.event.id == event.id }
        }
    }

    private func notificationEvent(from validationError: ValidationError) -> SendNotificationEvent? {
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
            return .validationErrorEvent(validationErrorEvent)
        case .invalidNumber:
            return nil
        }
    }
}

extension CommonSendNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value + validationErrorInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Publishers.CombineLatest(notificationInputsSubject, validationErrorInputsSubject)
            .map {
                $0 + $1
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {}
}
