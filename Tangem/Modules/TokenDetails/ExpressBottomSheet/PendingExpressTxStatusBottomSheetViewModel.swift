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
        pendingTransaction.transactionRecord.externalTxId
    }

    var animationDuration: TimeInterval {
        Constants.animationDuration
    }

    let expressBranch: ExpressBranch

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

    private let pendingTransaction: PendingExpressTransaction
    private let currentTokenItem: TokenItem

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?
    private var notificationUpdateWorkItem: DispatchWorkItem?
    private weak var router: PendingExpressTxStatusRoutable?
    private var successToast: Toast<SuccessToast>?
    private var externalProviderTxURL: URL? {
        pendingTransaction.transactionRecord.externalTxURL.flatMap { URL(string: $0) }
    }

    init(
        expressBranch: ExpressBranch,
        pendingTransaction: PendingExpressTransaction,
        currentTokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager,
        router: PendingExpressTxStatusRoutable
    ) {
        self.expressBranch = expressBranch
        self.pendingTransaction = pendingTransaction
        self.currentTokenItem = currentTokenItem
        self.pendingTransactionsManager = pendingTransactionsManager
        self.router = router

        let provider = pendingTransaction.transactionRecord.provider
        
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
        timeString = dateFormatter.string(from: pendingTransaction.transactionRecord.date)

        let sourceTokenTxInfo = pendingTransaction.transactionRecord.sourceTokenTxInfo
        let sourceTokenItem = sourceTokenTxInfo.tokenItem
        let destinationTokenTxInfo = pendingTransaction.transactionRecord.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        let iconInfoBuilder = TokenIconInfoBuilder()
        sourceTokenIconInfo = iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom)
        destinationTokenIconInfo = iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom)

        sourceAmountText = balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol)
        destinationAmountText = balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol)

        loadEmptyFiatRates()
        updateUI(with: pendingTransaction, delay: 0)
        bind()
    }

    func onAppear() {
        Analytics.log(
            event: .tokenSwapStatusScreenOpened,
            params: [
                .token: currentTokenItem.currencySymbol,
                .provider: pendingTransaction.transactionRecord.provider.name,
            ]
        )
    }

    func openProviderFromStatusHeader() {
        Analytics.log(
            event: .tokenButtonGoToProvider,
            params: [
                .token: currentTokenItem.currencySymbol,
                .place: Analytics.ParameterValue.status.rawValue,
            ]
        )

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
        router?.openCurrency(tokenItem: tokenItem)
    }

    private func loadEmptyFiatRates() {
        loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: pendingTransaction.transactionRecord.sourceTokenTxInfo, on: self)
        loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: pendingTransaction.transactionRecord.destinationTokenTxInfo, on: self)
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
                    tx.transactionRecord.expressTransactionId == viewModel.pendingTransaction.transactionRecord.expressTransactionId
                }) else {
                    return (viewModel, nil)
                }

                return (viewModel, first)
            }
            .receive(on: DispatchQueue.main)
            .sink { (viewModel: PendingExpressTxStatusBottomSheetViewModel, pendingTx: PendingExpressTransaction?) in
                // If we've failed to find this transaction in manager it means that it was finished in either way on the provider side
                // We can remove subscription and just display final state of transaction
                guard let pendingTx else {
                    viewModel.subscription = nil
                    return
                }

                // We will hide it via separate notification in case of refunded token
                if pendingTx.transactionRecord.transactionStatus.isTerminated, pendingTx.transactionRecord.refundedTokenItem == nil {
                    viewModel.hidePendingTx(expressTransactionId: pendingTx.transactionRecord.expressTransactionId)
                }

                viewModel.updateUI(with: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func hidePendingTx(expressTransactionId: String) {
        pendingTransactionsManager?.hideTransaction(with: expressTransactionId)
    }

    private func updateUI(with pendingTransaction: PendingExpressTransaction, delay: TimeInterval) {
        let converter = PendingExpressTransactionsConverter()
        let (list, currentIndex) = converter.convertToStatusRowDataList(for: pendingTransaction)

        updateUI(
            statusesList: list,
            currentIndex: currentIndex,
            currentStatus: pendingTransaction.transactionRecord.transactionStatus,
            refundedTokenItem: pendingTransaction.transactionRecord.refundedTokenItem,
            hasExternalURL: pendingTransaction.transactionRecord.externalTxURL != nil,
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
            hidePendingTx(expressTransactionId: pendingTransaction.transactionRecord.expressTransactionId)
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
