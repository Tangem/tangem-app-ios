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
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }
    var customFeePublisher: AnyPublisher<Fee?, Never> { get }
    var withdrawalSuggestion: AnyPublisher<WithdrawalSuggestion?, Never> { get }
    var transactionCreationError: AnyPublisher<Error?, Never> { get }
}

protocol SendNotificationManager: NotificationManager {
    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never>
    func hasNotifications(with severity: NotificationView.Severity) -> AnyPublisher<Bool, Never>
}

class CommonSendNotificationManager: SendNotificationManager {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let input: SendNotificationManagerInput
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private let transactionCreationNotificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
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

    init(tokenItem: TokenItem, feeTokenItem: TokenItem, input: SendNotificationManagerInput) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.input = input
    }

    func notificationPublisher(for location: SendNotificationEvent.Location) -> AnyPublisher<[NotificationViewInput], Never> {
        notificationPublisher
            .map {
                $0.filter { input in
                    let sendNotificationEvent = input.settings.event as? SendNotificationEvent
                    return sendNotificationEvent?.location == location
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

    private func bind() {
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
            .withdrawalSuggestion
            .sink { [weak self] withdrawalSuggestion in
                guard let self else { return }

                switch withdrawalSuggestion {
                case .feeIsTooHigh(let newAmount):
                    let event = SendNotificationEvent.withdrawalOptionalAmountChange(
                        amount: newAmount.value,
                        amountFormatted: newAmount.string()
                    )
                    updateEventVisibility(true, event: event)
                case nil:
                    let events = [
                        SendNotificationEvent.withdrawalOptionalAmountChange(amount: .zero, amountFormatted: ""),
                    ]
                    for event in events {
                        updateEventVisibility(false, event: event)
                    }
                }
            }
            .store(in: &bag)

        let loadedFeeValues = input
            .feeValues
            .compactMap { loadingFeeValues -> [FeeOption: Decimal]? in
                if loadingFeeValues.values.contains(where: { $0.isLoading }) {
                    return nil
                }

                return loadingFeeValues.compactMapValues { $0.value?.amount.value }
            }
        let customFeeValue = input
            .customFeePublisher
            .compactMap {
                $0?.amount.value
            }
        Publishers.CombineLatest(loadedFeeValues, customFeeValue)
            .sink { [weak self] loadedFeeValues, customFee in
                guard
                    let lowestFee = loadedFeeValues[.slow],
                    let highestFee = loadedFeeValues[.fast]
                else {
                    return
                }

                let tooLow = customFee < lowestFee
                self?.updateEventVisibility(tooLow, event: .customFeeTooLow)

                let highFeeOrderTrigger = 5
                let tooHigh = customFee > (highestFee * Decimal(highFeeOrderTrigger))
                self?.updateEventVisibility(tooHigh, event: .customFeeTooHigh(orderOfMagnitude: highFeeOrderTrigger))
            }
            .store(in: &bag)

        input
            .transactionCreationError
            .map {
                $0 as? ValidationError
            }
            .withWeakCaptureOf(self)
            .map { (self, validationError) -> [NotificationViewInput] in
                guard let validationError else { return [] }
                let factory = NotificationsFactory()

                guard let event = self.notificationEvent(from: validationError) else { return [] }

                let input = factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                    self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                } dismissAction: { [weak self] id in
                    self?.dismissAction(with: id)
                }
                return [input]
            }
            .assign(to: \.value, on: transactionCreationNotificationInputsSubject, ownership: .weak)
            .store(in: &bag)
    }

    private func dismissAction(with settingsId: NotificationViewId) {
        notificationInputsSubject.value.removeAll {
            $0.settings.id == settingsId
        }
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if visible {
            if !notificationInputsSubject.value.contains(where: { $0.settings.event.id == event.id }) {
                let factory = NotificationsFactory()

                let input = factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                    self?.delegate?.didTapNotificationButton(with: id, action: actionType)
                } dismissAction: { [weak self] id in
                    self?.dismissAction(with: id)
                }
                notificationInputsSubject.value.append(input)
            }
        } else {
            notificationInputsSubject.value.removeAll { $0.settings.event.id == event.id }
        }
    }

    private func notificationEvent(from validationError: ValidationError) -> SendNotificationEvent? {
        switch validationError {
        case .dustAmount(let minimumAmount), .dustChange(let minimumAmount):
            return SendNotificationEvent.minimumAmount(value: minimumAmount.string())
        case .totalExceedsBalance:
            return .totalExceedsBalance(configuration: notEnoughFeeConfiguration)
        case .feeExceedsBalance:
            return .feeExceedsBalance(configuration: notEnoughFeeConfiguration)
        case .minimumBalance(let minimumBalance):
            return .existentialDeposit(amountFormatted: minimumBalance.string())
        case .maximumUTXO(let blockchainName, let newAmount, let maxUtxos):
            return SendNotificationEvent.withdrawalMandatoryAmountChange(
                amount: newAmount.value,
                amountFormatted: newAmount.string(),
                blockchainName: blockchainName,
                maxUtxo: maxUtxos
            )
        default:
            return nil
        }
    }
}

extension CommonSendNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value + transactionCreationNotificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        Publishers.CombineLatest(notificationInputsSubject, transactionCreationNotificationInputsSubject)
            .map {
                $0 + $1
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {}
}
