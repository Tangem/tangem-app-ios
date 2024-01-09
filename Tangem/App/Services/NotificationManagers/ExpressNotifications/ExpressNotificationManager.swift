//
//  ExpressNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 21/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct TangemSwapping.ExpressAPIError

class ExpressNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var expressInteractor: ExpressInteractor?
    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService = .init()

    private var subscription: AnyCancellable?
    private var priceImpactTask: Task<Void, Error>?
    private var depositTask: Task<Void, Error>?

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor

        bind()
    }

    private func bind() {
        subscription = expressInteractor?.state
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: ExpressNotificationManager.setupNotifications(for:)))
    }

    private func setupNotifications(for state: ExpressInteractor.ExpressInteractorState) {
        priceImpactTask?.cancel()
        priceImpactTask = nil

        switch state {
        case .idle:
            notificationInputsSubject.value = []
        case .loading(.refreshRates):
            break
        case .loading(.full):
            notificationInputsSubject.value = notificationInputsSubject.value.filter {
                guard let event = $0.settings.event as? ExpressNotificationEvent else {
                    return false
                }

                return !event.removingOnFullLoadingState
            }
        case .restriction(let restrictions, let quote):
            setupNotification(for: restrictions)

            guard let quote else {
                return
            }

            checkHighPriceImpact(fromAmount: quote.fromAmount, toAmount: quote.expectAmount)
        case .permissionRequired:
            setupPermissionRequiredNotification()

        case .readyToSwap(_, let quote):
            notificationInputsSubject.value = []
            checkHighPriceImpact(fromAmount: quote.fromAmount, toAmount: quote.expectAmount)
            // We have not the subtractFee on DEX
            setupExistentialDepositWarning(amount: quote.fromAmount, subtractFee: 0)

        case .previewCEX(let preview, let quote):
            if let notification = makeFeeWillBeSubtractFromSendingAmountNotification(subtractFee: preview.subtractFee) {
                // If this notification already showed then will not update the notifications set
                if !notificationInputsSubject.value.contains(where: { $0.id == notification.id }) {
                    notificationInputsSubject.value = [notification]
                }
            } else {
                notificationInputsSubject.value = []
            }

            checkHighPriceImpact(fromAmount: quote.fromAmount, toAmount: quote.expectAmount)
            setupExistentialDepositWarning(amount: quote.fromAmount, subtractFee: preview.subtractFee)
        }
    }

    private func setupExistentialDepositWarning(amount: Decimal, subtractFee: Decimal) {
        depositTask = runTask(in: self) { manager in
            guard let notification = try await manager.makeExistentialDepositWarningIfNeeded(amount: amount, subtractFee: subtractFee) else {
                return
            }

            manager.notificationInputsSubject.value.append(notification)
        }
    }

    private func checkHighPriceImpact(fromAmount: Decimal, toAmount: Decimal) {
        priceImpactTask = runTask(in: self, code: { manager in
            guard let notification = try await manager.makeHighPriceImpactIfNeeded(
                fromAmount: fromAmount,
                toAmount: toAmount
            ) else {
                return
            }

            manager.notificationInputsSubject.value.append(notification)
        })
    }

    private func setupNotification(for restrictions: ExpressInteractor.RestrictionType) {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let event: ExpressNotificationEvent
        let notificationsFactory = NotificationsFactory()

        switch restrictions {
        case .notEnoughAmountForSwapping(let minAmount):
            let sourceTokenItemSymbol = sourceTokenItem.currencySymbol
            event = .notEnoughAmountToSwap(minimumAmountText: "\(minAmount) \(sourceTokenItemSymbol)")
        case .hasPendingTransaction:
            event = .hasPendingTransaction(symbol: sourceTokenItem.currencySymbol)
        case .hasPendingApproveTransaction:
            event = .hasPendingApproveTransaction
        case .notEnoughBalanceForSwapping(let requiredAmount):
            notificationInputsSubject.value = []
            return
        case .notEnoughAmountForFee:
            guard sourceTokenItem.isToken else {
                notificationInputsSubject.value = []
                return
            }

            let sourceNetworkSymbol = sourceTokenItem.blockchain.currencySymbol
            event = .notEnoughFeeForTokenTx(mainTokenName: sourceTokenItem.blockchain.displayName, mainTokenSymbol: sourceNetworkSymbol, blockchainIconName: sourceTokenItem.blockchain.iconNameFilled)
        case .requiredRefresh(let occurredError as ExpressAPIError):
            // For only a express error we use "Service temporary unavailable"
            let message = Localization.expressErrorCode(occurredError.errorCode.localizedDescription)
            event = .refreshRequired(title: Localization.warningExpressRefreshRequiredTitle, message: message)
        case .requiredRefresh:
            event = .refreshRequired(title: Localization.commonError, message: Localization.expressUnknownError)
        case .noDestinationTokens:
            let sourceTokenItemName = sourceTokenItem.name
            event = .noDestinationTokens(sourceTokenName: sourceTokenItemName)
        }

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func setupPermissionRequiredNotification() {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let event: ExpressNotificationEvent = .permissionNeeded(currencyCode: sourceTokenItem.currencySymbol)
        let notificationsFactory = NotificationsFactory()

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotificationButton(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func makeExistentialDepositWarningIfNeeded(amount: Decimal, subtractFee: Decimal) async throws -> NotificationViewInput? {
        guard let sender = expressInteractor?.getSender(),
              let provider = sender.existentialDepositProvider else {
            return nil
        }

        let balance = try await sender.getBalance()
        let remainBalance = balance - (amount + subtractFee)

        guard remainBalance < provider.existentialDeposit.value, let warning = sender.existentialDepositWarning else {
            return nil
        }

        let notificationsFactory = NotificationsFactory()
        let notification = notificationsFactory.buildNotificationInput(for: .existentialDepositWarning(message: warning))
        return notification
    }

    private func makeFeeWillBeSubtractFromSendingAmountNotification(subtractFee: Decimal) -> NotificationViewInput? {
        guard subtractFee > 0 else { return nil }
        let factory = NotificationsFactory()
        let notification = factory.buildNotificationInput(for: .feeWillBeSubtractFromSendingAmount)
        return notification
    }

    private func makeHighPriceImpactIfNeeded(fromAmount: Decimal, toAmount: Decimal) async throws -> NotificationViewInput? {
        guard
            let sourceCurrencyId = expressInteractor?.getSender().tokenItem.currencyId,
            let destinationCurrencyId = expressInteractor?.getDestination()?.tokenItem.currencyId,
            // We've decided don't show the "HighPriceImpact" for CEX providers
            await expressInteractor?.getSelectedProvider()?.provider.type != .cex
        else {
            return nil
        }

        let priceImpactCalculator = HighPriceImpactCalculator(sourceCurrencyId: sourceCurrencyId, destinationCurrencyId: destinationCurrencyId)
        let result = try await priceImpactCalculator.isHighPriceImpact(converting: fromAmount, to: toAmount)

        if Task.isCancelled {
            return nil
        }

        guard result.isHighPriceImpact else {
            return nil
        }

        let factory = NotificationsFactory()
        let notification = factory.buildNotificationInput(for: .highPriceImpact)
        return notification
    }
}

extension ExpressNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupNotifications(for: expressInteractor?.getState() ?? .idle)
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
