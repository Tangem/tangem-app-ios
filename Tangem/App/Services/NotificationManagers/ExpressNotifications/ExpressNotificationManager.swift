//
//  ExpressNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 21/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import struct TangemExpress.ExpressAPIError

class ExpressNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var expressInteractor: ExpressInteractor?
    private weak var delegate: NotificationTapDelegate?
    private var analyticsService: NotificationsAnalyticsService = .init()

    private var subscription: AnyCancellable?

    init(expressInteractor: ExpressInteractor) {
        self.expressInteractor = expressInteractor
        analyticsService.setup(with: self, contextDataProvider: nil)

        bind()
    }

    private func bind() {
        subscription = expressInteractor?.state
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: ExpressNotificationManager.setupNotifications(for:)))
    }

    private func setupNotifications(for state: ExpressInteractor.State) {
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
        case .restriction(let restrictions, _):
            runTask(in: self) { manager in
                await manager.setupNotification(for: restrictions)
            }

        case .permissionRequired:
            setupPermissionRequiredNotification()

        case .readyToSwap:
            notificationInputsSubject.value = []

        case .previewCEX(let preview, _):
            notificationInputsSubject.value = [
                setupFeeWillBeSubtractFromSendingAmountNotification(subtractFee: preview.subtractFee),
                setupWithdrawalInput(notification: preview.notification),
            ].compactMap { $0 }
        }
    }

    private func setupNotification(for restrictions: ExpressInteractor.RestrictionType) async {
        guard let interactor = expressInteractor else { return }

        let sourceTokenItem = interactor.getSender().tokenItem
        let sourceTokenItemSymbol = sourceTokenItem.currencySymbol
        let event: ExpressNotificationEvent
        let notificationsFactory = NotificationsFactory()

        switch restrictions {
        case .tooSmallAmountForSwapping(let minAmount):
            event = .tooSmallAmountToSwap(minimumAmountText: "\(minAmount) \(sourceTokenItemSymbol)")
        case .tooBigAmountForSwapping(let maxAmount):
            event = .tooBigAmountToSwap(maximumAmountText: "\(maxAmount) \(sourceTokenItemSymbol)")
        case .hasPendingTransaction:
            event = .hasPendingTransaction(symbol: sourceTokenItemSymbol)
        case .hasPendingApproveTransaction:
            event = .hasPendingApproveTransaction
        case .notEnoughBalanceForSwapping:
            notificationInputsSubject.value = []
            return
        case .validationError(let error, let context):
            setupNotification(for: error, context: context)
            return
        case .notEnoughAmountForFee, .notEnoughAmountForTxValue:
            guard let notEnoughFeeForTokenTxEvent = makeNotEnoughFeeForTokenTx(sender: interactor.getSender()) else {
                notificationInputsSubject.value = []
                return
            }

            event = notEnoughFeeForTokenTxEvent
        case .notEnoughReceivedAmount(let minAmount, let tokenSymbol):
            event = .notEnoughReceivedAmountForReserve(amountFormatted: "\(minAmount.formatted()) \(tokenSymbol)")
        case .requiredRefresh(let occurredError as ExpressAPIError):
            // For only a express error we use "Service temporary unavailable"
            // or "Selected pair temporarily unavailable" depending on the error code.
            var analyticsParams: [Analytics.ParameterKey: String] = [
                .sendToken: sourceTokenItemSymbol,
                .errorCode: "\(occurredError.errorCode.rawValue)",
            ]

            if let provider = await interactor.getSelectedProvider()?.provider.name {
                analyticsParams[.provider] = provider
            }

            if let receiveToken = interactor.getDestination()?.tokenItem.currencySymbol {
                analyticsParams[.receiveToken] = receiveToken
            }

            event = .refreshRequired(
                title: occurredError.localizedTitle,
                message: occurredError.localizedMessage,
                expressErrorCode: occurredError.errorCode,
                analyticsParams: analyticsParams
            )
        case .requiredRefresh:
            event = .refreshRequired(title: Localization.commonError, message: Localization.commonUnknownError)
        case .noDestinationTokens:
            let sourceTokenItemName = sourceTokenItem.name
            event = .noDestinationTokens(sourceTokenName: sourceTokenItemName)
        }

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }

    private func setupNotification(for validationError: ValidationError, context: ValidationErrorContext) {
        guard let interactor = expressInteractor else { return }

        let sender = interactor.getSender()
        let factory = BlockchainSDKNotificationMapper(tokenItem: sender.tokenItem, feeTokenItem: sender.feeTokenItem)
        let validationErrorEvent = factory.mapToValidationErrorEvent(validationError)
        let event: ExpressNotificationEvent

        switch validationErrorEvent {
        case .invalidNumber:
            event = .refreshRequired(title: Localization.commonError, message: validationError.localizedDescription)
        case .insufficientBalance:
            assertionFailure("It have to be mapped to ExpressInteractor.RestrictionType.notEnoughBalanceForSwapping")
            notificationInputsSubject.value = []
            return
        case .insufficientBalanceForFee:
            assertionFailure("It have to be mapped to ExpressInteractor.RestrictionType.notEnoughAmountForFee")
            guard let notEnoughFeeForTokenTxEvent = makeNotEnoughFeeForTokenTx(sender: sender) else {
                notificationInputsSubject.value = []
                return
            }

            event = notEnoughFeeForTokenTxEvent

        case .dustRestriction,
             .existentialDeposit,
             .amountExceedMaximumUTXO,
             .insufficientAmountToReserveAtDestination,
             .cardanoCannotBeSentBecauseHasTokens,
             .cardanoInsufficientBalanceToSendToken,
             .notEnoughMana,
             .manaLimit,
             .koinosInsufficientBalanceToSendKoin:
            event = .validationErrorEvent(event: validationErrorEvent, context: context)
        }

        let notification = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }

        notificationInputsSubject.value = [notification]
    }

    private func setupPermissionRequiredNotification() {
        runTask(in: self) { manager in
            guard let interactor = manager.expressInteractor else { return }

            let sourceTokenItem = interactor.getSender().tokenItem
            let selectedProvider = await interactor.getSelectedProvider()?.provider
            let event: ExpressNotificationEvent = .permissionNeeded(
                providerName: selectedProvider?.name ?? "",
                currencyCode: sourceTokenItem.currencySymbol
            )
            let notificationsFactory = NotificationsFactory()

            let notification = notificationsFactory.buildNotificationInput(for: event) { [weak manager] id, actionType in
                manager?.delegate?.didTapNotification(with: id, action: actionType)
            }
            manager.notificationInputsSubject.value = [notification]
        }
    }

    private func setupFeeWillBeSubtractFromSendingAmountNotification(subtractFee: Decimal) -> NotificationViewInput? {
        guard let interactor = expressInteractor, subtractFee > 0 else {
            return nil
        }

        let feeTokenItem = interactor.getSender().feeTokenItem
        let feeFiatValue = BalanceConverter().convertToFiat(subtractFee, currencyId: feeTokenItem.currencyId ?? "")

        let formatter = BalanceFormatter()
        let cryptoAmountFormatted = formatter.formatCryptoBalance(subtractFee, currencyCode: feeTokenItem.currencySymbol)
        let fiatAmountFormatted = formatter.formatFiatBalance(feeFiatValue)

        let event = ExpressNotificationEvent.feeWillBeSubtractFromSendingAmount(
            cryptoAmountFormatted: cryptoAmountFormatted,
            fiatAmountFormatted: fiatAmountFormatted
        )

        let notification = NotificationsFactory().buildNotificationInput(for: event)
        return notification
    }

    private func makeNotEnoughFeeForTokenTx(sender: WalletModel) -> ExpressNotificationEvent? {
        guard !sender.isFeeCurrency else {
            return nil
        }

        return .notEnoughFeeForTokenTx(
            mainTokenName: sender.feeTokenItem.blockchain.displayName,
            mainTokenSymbol: sender.feeTokenItem.currencySymbol,
            blockchainIconName: sender.feeTokenItem.blockchain.iconNameFilled
        )
    }

    private func setupWithdrawalInput(notification: WithdrawalNotification?) -> NotificationViewInput? {
        guard let interactor = expressInteractor, let notification else {
            return nil
        }

        let sender = interactor.getSender()
        let factory = BlockchainSDKNotificationMapper(tokenItem: sender.tokenItem, feeTokenItem: sender.feeTokenItem)
        let withdrawalNotification = factory.mapToWithdrawalNotificationEvent(notification)

        let event = ExpressNotificationEvent.withdrawalNotificationEvent(withdrawalNotification)
        let input = NotificationsFactory().buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }
        return input
    }
}

extension ExpressAPIError {
    var localizedTitle: String {
        switch errorCode {
        case .exchangeNotPossibleError:
            Localization.warningExpressPairUnavailableTitle
        default:
            Localization.warningExpressRefreshRequiredTitle
        }
    }

    var localizedMessage: String {
        switch errorCode {
        case .exchangeInternalError:
            return Localization.expressErrorSwapUnavailable(errorCode.rawValue)
        case .exchangeProviderNotActiveError, .exchangeProviderNotAvailableError, .exchangeProviderProviderInternalError:
            return Localization.expressErrorSwapPairUnavailable(errorCode.rawValue)
        case .exchangeNotPossibleError:
            return Localization.warningExpressPairUnavailableMessage(errorCode.rawValue)
        default:
            return Localization.expressErrorCode(errorCode.localizedDescription)
        }
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
