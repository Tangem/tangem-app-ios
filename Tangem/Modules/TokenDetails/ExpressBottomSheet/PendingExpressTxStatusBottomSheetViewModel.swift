//
//  PendingExpressTxStatusBottomSheetViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 01/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress
import UIKit

class PendingExpressTxStatusBottomSheetViewModel: ObservableObject, Identifiable {
    var transactionID: String? {
        pendingTransaction.externalTxId
    }

    var animationDuration: TimeInterval {
        Constants.animationDuration
    }

    let sheetTitle: String
    let statusViewTitle: String

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var providerRowViewModel: ProviderRowViewModel
    @Published var sourceFiatAmountTextState: LoadableTextView.State = .loading
    @Published var destinationFiatAmountTextState: LoadableTextView.State = .loading
    @Published var statusesList: [PendingExpressTxStatusRow.StatusRowData] = []
    @Published var currentStatusIndex = 0
    @Published var showGoToProviderHeaderButton = true
    @Published var notificationViewInputs: [NotificationViewInput] = []

    private let expressProviderFormatter = ExpressProviderFormatter(balanceFormatter: .init())
    private weak var pendingTransactionsManager: (any PendingExpressTransactionsManager)?

    private let pendingTransaction: PendingTransaction
    private let currentTokenItem: TokenItem
    private let userWalletModel: UserWalletModel

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?
    private var notificationUpdateWorkItem: DispatchWorkItem?
    private weak var router: PendingExpressTxStatusRoutable?
    private var successToast: Toast<SuccessToast>?
    private var externalProviderTxURL: URL? {
        pendingTransaction.externalTxURL.flatMap { URL(string: $0) }
    }

    init(
        pendingTransaction: PendingTransaction,
        currentTokenItem: TokenItem,
        userWalletModel: UserWalletModel,
        pendingTransactionsManager: PendingExpressTransactionsManager,
        router: PendingExpressTxStatusRoutable
    ) {
        self.pendingTransaction = pendingTransaction
        self.currentTokenItem = currentTokenItem
        self.userWalletModel = userWalletModel
        self.pendingTransactionsManager = pendingTransactionsManager
        self.router = router

        let provider = pendingTransaction.provider
        let iconBuilder = TokenIconInfoBuilder()

        switch pendingTransaction.type {
        case .swap(let source, let destination):
            sheetTitle = Localization.expressExchangeStatusTitle
            statusViewTitle = Localization.expressExchangeBy(provider.name)
            sourceAmountText = balanceFormatter.formatCryptoBalance(source.amount, currencyCode: source.tokenItem.currencySymbol)
            destinationAmountText = balanceFormatter.formatCryptoBalance(destination.amount, currencyCode: destination.tokenItem.currencySymbol)
            sourceTokenIconInfo = iconBuilder.build(from: source.tokenItem, isCustom: source.isCustom)
            destinationTokenIconInfo = iconBuilder.build(from: destination.tokenItem, isCustom: destination.isCustom)
        case .onramp(let sourceAmount, let sourceCurrencySymbol, let destination):
            sheetTitle = Localization.commonTransactionStatus
            statusViewTitle = Localization.commonTransactionStatus
            sourceAmountText = balanceFormatter.formatFiatBalance(sourceAmount, currencyCode: sourceCurrencySymbol)
            destinationAmountText = balanceFormatter.formatCryptoBalance(destination.amount, currencyCode: destination.tokenItem.currencySymbol)
            sourceTokenIconInfo = iconBuilder.build(from: sourceCurrencySymbol)
            destinationTokenIconInfo = iconBuilder.build(from: destination.tokenItem, isCustom: destination.isCustom)
        }

        providerRowViewModel = .init(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            titleFormat: .name,
            isDisabled: false,
            badge: .none,
            subtitles: [.text(Localization.expressFloatingRate)],
            detailsType: .none
        )

        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        timeString = dateFormatter.string(from: pendingTransaction.date)

        loadEmptyFiatRates()
        updateUI(with: pendingTransaction, delay: 0)
        bind()
    }

    func onAppear() {
        var params: [Analytics.ParameterKey: String] = [
            .token: currentTokenItem.currencySymbol,
            .provider: pendingTransaction.provider.name,
        ]

        switch pendingTransaction.type {
        case .onramp(_, let currency, _):
            params[.currency] = currency
            Analytics.log(event: .onrampOnrampStatusOpened, params: params)

            if pendingTransaction.transactionStatus == .verificationRequired {
                Analytics.log(event: .onrampNoticeKYC, params: params)
            }

        case .swap:
            Analytics.log(event: .tokenSwapStatusScreenOpened, params: params)
        }
    }

    func openProviderFromStatusHeader() {
        let params: [Analytics.ParameterKey: String] = [
            .token: currentTokenItem.currencySymbol,
            .provider: pendingTransaction.provider.name,
            .place: Analytics.ParameterValue.status.rawValue,
        ]

        switch pendingTransaction.type {
        case .onramp:
            Analytics.log(event: .onrampButtonGoToProvider, params: params)
        case .swap:
            Analytics.log(event: .tokenButtonGoToProvider, params: params)
        }

        openProvider()
    }

    func copyTransactionID() {
        UIPasteboard.general.string = transactionID

        let toastView = SuccessToast(text: Localization.expressTransactionIdCopied)
        successToast = Toast(view: toastView)
        successToast?.present(layout: .top(padding: 14), type: .temporary())
    }

    private func openProvider() {
        guard let url = externalProviderTxURL else {
            return
        }

        router?.openURL(url)
    }

    private func openCurrency(tokenItem: TokenItem) {
        Analytics.log(.tokenButtonGoToToken)
        router?.openCurrency(tokenItem: tokenItem, userWalletModel: userWalletModel)
    }

    private func loadEmptyFiatRates() {
        switch pendingTransaction.type {
        case .swap(let source, let destination):
            loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: source, on: self)
            loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: destination, on: self)
        case .onramp(_, _, let destination):
            sourceFiatAmountTextState = .noData
            loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: destination, on: self)
        }
    }

    private func loadRatesIfNeeded(
        stateKeyPath: ReferenceWritableKeyPath<PendingExpressTxStatusBottomSheetViewModel, LoadableTextView.State>,
        for tokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo,
        on root: PendingExpressTxStatusBottomSheetViewModel
    ) {
        guard let currencyId = tokenTxInfo.tokenItem.currencyId else {
            root[keyPath: stateKeyPath] = .noData
            return
        }

        if let fiat = balanceConverter.convertToFiat(tokenTxInfo.amount, currencyId: currencyId) {
            root[keyPath: stateKeyPath] = .loaded(text: balanceFormatter.formatFiatBalance(fiat))
            return
        }

        Task { [weak root] in
            guard let root = root else { return }

            let fiatAmount = try await root.balanceConverter.convertToFiat(tokenTxInfo.amount, currencyId: currencyId)
            let formattedFiat = root.balanceFormatter.formatFiatBalance(fiatAmount)
            await runOnMain {
                root[keyPath: stateKeyPath] = .loaded(text: formattedFiat)
            }
        }
    }

    private func bind() {
        subscription = pendingTransactionsManager?.pendingTransactionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTransactions in
                guard let first = pendingTransactions.first(where: { tx in
                    tx.expressTransactionId == viewModel.pendingTransaction.expressTransactionId
                }) else {
                    return (viewModel, nil)
                }

                return (viewModel, first)
            }
            .receive(on: DispatchQueue.main)
            .sink { (viewModel: PendingExpressTxStatusBottomSheetViewModel, pendingTx: PendingTransaction?) in
                // If we've failed to find this transaction in manager it means that it was finished in either way on the provider side
                // We can remove subscription and just display final state of transaction
                guard let pendingTx else {
                    viewModel.subscription = nil
                    return
                }

                // We will hide it via separate notification in case of refunded token
                if pendingTx.transactionStatus.isTerminated(branch: pendingTx.type.branch),
                   pendingTx.refundedTokenItem == nil {
                    viewModel.hidePendingTx(expressTransactionId: pendingTx.expressTransactionId)
                }

                viewModel.updateUI(with: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func hidePendingTx(expressTransactionId: String) {
        pendingTransactionsManager?.hideTransaction(with: expressTransactionId)
    }

    private func updateUI(with pendingTransaction: PendingTransaction, delay: TimeInterval) {
        let converter = PendingExpressTransactionsConverter()
        let (list, currentIndex) = converter.convertToStatusRowDataList(for: pendingTransaction)

        updateUI(
            statusesList: list,
            currentIndex: currentIndex,
            currentStatus: pendingTransaction.transactionStatus,
            refundedTokenItem: pendingTransaction.refundedTokenItem,
            hasExternalURL: pendingTransaction.externalTxURL != nil,
            delay: delay
        )
    }

    private func updateUI(
        statusesList: [PendingExpressTxStatusRow.StatusRowData],
        currentIndex: Int,
        currentStatus: PendingExpressTransactionStatus,
        refundedTokenItem: TokenItem?,
        hasExternalURL: Bool,
        delay: TimeInterval
    ) {
        self.statusesList = statusesList
        currentStatusIndex = currentIndex

        let notificationFactory = NotificationsFactory()

        var inputs: [NotificationViewInput] = []

        switch currentStatus {
        case .failed:
            showGoToProviderHeaderButton = false

            if hasExternalURL {
                let input = notificationFactory.buildNotificationInput(
                    for: ExpressNotificationEvent.cexOperationFailed,
                    buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
                )

                inputs.append(input)
            }

        case .verificationRequired:
            showGoToProviderHeaderButton = false
            let input = notificationFactory.buildNotificationInput(
                for: ExpressNotificationEvent.verificationRequired,
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )

            inputs.append(input)

        case .canceled:
            showGoToProviderHeaderButton = false
        default:
            showGoToProviderHeaderButton = externalProviderTxURL != nil
        }

        if let refundedTokenItem {
            let input = notificationFactory.buildNotificationInput(
                for: ExpressNotificationEvent.refunded(tokenItem: refundedTokenItem),
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )

            inputs.append(input)
        }

        scheduleNotificationUpdate(inputs, delay: delay)
    }

    private func scheduleNotificationUpdate(_ newInputs: [NotificationViewInput], delay: TimeInterval) {
        notificationUpdateWorkItem?.cancel()
        notificationUpdateWorkItem = nil

        notificationUpdateWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.notificationViewInputs = newInputs
        })

        // We need to delay notification appearance/disappearance animations
        // to prevent glitches while updating other views (labels, icons, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: notificationUpdateWorkItem!)
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard let notificationViewInput = notificationViewInputs.first(where: { $0.id == id }),
              let event = notificationViewInput.settings.event as? ExpressNotificationEvent else {
            return
        }

        switch event {
        case .verificationRequired:
            Analytics.log(
                event: .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: Analytics.ParameterValue.kyc.rawValue,
                ]
            )

            openProvider()

        case .cexOperationFailed:
            Analytics.log(
                event: .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: Analytics.ParameterValue.fail.rawValue,
                ]
            )

            openProvider()

        case .refunded(let tokenItem):
            hidePendingTx(expressTransactionId: pendingTransaction.expressTransactionId)
            openCurrency(tokenItem: tokenItem)

        default:
            break
        }
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static var notificationAnimationDelay: TimeInterval {
            animationDuration + 0.05
        }
    }
}
