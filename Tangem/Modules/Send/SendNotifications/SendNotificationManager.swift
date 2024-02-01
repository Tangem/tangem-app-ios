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
    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> { get }
}

class SendNotificationManager {
    private let input: SendNotificationManagerInput
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: NotificationTapDelegate?

    init(input: SendNotificationManagerInput) {
        self.input = input
    }

    var buttonAction: NotificationView.NotificationButtonTapAction {
        delegate?.didTapNotificationButton(with:action:) ?? { _, _ in }
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

    private func bind() {
        input
            .feeValues
            .map {
                $0.contains(where: { $0.value.error != nil })
            }
            .sink { [weak self] hasError in
                self?.updateEventVisibility(hasError, event: .networkFeeUnreachable)
            }
            .store(in: &bag)

        #warning("TODO")
        let sendModel = (input as! SendModel)
        let loadedFeeValues = sendModel
            .feeValues
            .compactMap { loadingFeeValues -> [Decimal]? in
                if loadingFeeValues.values.contains(where: { $0.isLoading }) {
                    return nil
                }

                return loadingFeeValues.values.compactMap { $0.value?.amount.value }
            }

        let customFeeValue = sendModel
            .customFeePublisher
            .compactMap {
                $0?.amount.value
            }

        Publishers.CombineLatest(loadedFeeValues, customFeeValue)
            .sink { [weak self] loadedFees, customFee in
                guard
                    let lowestFee = loadedFees.first,
                    let highestFee = loadedFees.last
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
            .isFeeIncludedPublisher
            .sink { [weak self] isFeeIncluded in
                self?.updateEventVisibility(isFeeIncluded, event: .feeCoverage)
            }
            .store(in: &bag)
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if visible {
            if !notificationInputsSubject.value.contains(where: { $0.settings.event.hashValue == event.hashValue }) {
                let input = NotificationsFactory().buildNotificationInput(for: event, buttonAction: buttonAction)
                notificationInputsSubject.value.append(input)
            }
        } else {
            notificationInputsSubject.value.removeAll { $0.settings.event.hashValue == event.hashValue }
        }
    }
}

extension SendNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {}
}
