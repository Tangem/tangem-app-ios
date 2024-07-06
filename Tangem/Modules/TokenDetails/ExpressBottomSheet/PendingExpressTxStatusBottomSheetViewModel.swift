//
//  PendingExpressTxStatusBottomSheetViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 01/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class PendingExpressTxStatusBottomSheetViewModel: ObservableObject, Identifiable {
    var transactionID: String? {
        pendingTransaction.transactionRecord.externalTxId
    }

    var animationDuration: TimeInterval {
        Constants.animationDuration
    }

    let timeString: String
    let sourceTokenIconInfo: TokenIconInfo
    let destinationTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let destinationAmountText: String

    @Published var providerRowViewModel: ProviderRowViewModel
    @Published var sourceFiatAmountTextState: LoadableTextView.State = .loading
    @Published var destinationFiatAmountTextState: LoadableTextView.State = .loading
    @Published var statusesList: [PendingExpressTransactionStatusRow.StatusRowData] = []
    @Published var currentStatusIndex = 0
    @Published var showGoToProviderHeaderButton = true
    @Published var notificationViewInput: NotificationViewInput? = nil

    private weak var pendingTransactionsManager: (any PendingExpressTransactionsManager)?

    private let pendingTransaction: PendingExpressTransaction
    private let currentTokenItem: TokenItem

    private let balanceConverter = BalanceConverter()
    private let balanceFormatter = BalanceFormatter()

    private var subscription: AnyCancellable?
    private var notificationUpdateWorkItem: DispatchWorkItem?
    private weak var router: PendingExpressTxStatusRoutable?
    private var successToast: Toast<SuccessToast>?

    init(
        pendingTransaction: PendingExpressTransaction,
        currentTokenItem: TokenItem,
        pendingTransactionsManager: PendingExpressTransactionsManager,
        router: PendingExpressTxStatusRoutable
    ) {
        self.pendingTransaction = pendingTransaction
        self.currentTokenItem = currentTokenItem
        self.pendingTransactionsManager = pendingTransactionsManager
        self.router = router

        let provider = pendingTransaction.transactionRecord.provider
        providerRowViewModel = .init(
            provider: .init(id: provider.id, iconURL: provider.iconURL, name: provider.name, type: provider.type.rawValue),
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
        Analytics.log(event: .tokenSwapStatusScreenOpened, params: [.token: currentTokenItem.currencySymbol])
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
        guard
            let urlString = pendingTransaction.transactionRecord.externalTxURL,
            let url = URL(string: urlString)
        else {
            return
        }

        router?.openPendingExpressTxStatus(at: url)
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

                if pendingTx.transactionRecord.transactionStatus.shouldHide {
                    viewModel.pendingTransactionsManager?.hideTransaction(with: pendingTx.transactionRecord.expressTransactionId)
                }

                viewModel.updateUI(with: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func updateUI(with pendingTransaction: PendingExpressTransaction, delay: TimeInterval) {
        let converter = PendingExpressTransactionsConverter()
        let (list, currentIndex) = converter.convertToStatusRowDataList(for: pendingTransaction)
        updateUI(
            statusesList: list,
            currentIndex: currentIndex,
            currentStatus: pendingTransaction.transactionRecord.transactionStatus,
            delay: delay
        )
    }

    private func updateUI(
        statusesList: [PendingExpressTransactionStatusRow.StatusRowData],
        currentIndex: Int,
        currentStatus: PendingExpressTransactionStatus,
        delay: TimeInterval
    ) {
        self.statusesList = statusesList
        currentStatusIndex = currentIndex

        let notificationFactory = NotificationsFactory()

        switch currentStatus {
        case .failed:
            showGoToProviderHeaderButton = false
            let input = notificationFactory.buildNotificationInput(
                for: .cexOperationFailed,
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )
            scheduleNotificationUpdate(input, delay: delay)

        case .verificationRequired:
            showGoToProviderHeaderButton = false
            let input = notificationFactory.buildNotificationInput(
                for: .verificationRequired,
                buttonAction: weakify(self, forFunction: PendingExpressTxStatusBottomSheetViewModel.didTapNotification(with:action:))
            )
            scheduleNotificationUpdate(input, delay: delay)

        case .canceled:
            showGoToProviderHeaderButton = false
            scheduleNotificationUpdate(nil, delay: delay)
        default:
            showGoToProviderHeaderButton = true
            scheduleNotificationUpdate(nil, delay: delay)
        }
    }

    private func scheduleNotificationUpdate(_ newInput: NotificationViewInput?, delay: TimeInterval) {
        notificationUpdateWorkItem?.cancel()
        notificationUpdateWorkItem = nil

        notificationUpdateWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.notificationViewInput = newInput
        })

        // We need to delay notification appearance/disappearance animations
        // to prevent glitches while updating other views (labels, icons, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: notificationUpdateWorkItem!)
    }
}

extension PendingExpressTxStatusBottomSheetViewModel {
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        guard let event = notificationViewInput?.settings.event as? ExpressNotificationEvent else {
            return
        }

        let placeValue: Analytics.ParameterValue?
        switch event {
        case .verificationRequired:
            placeValue = .kyc
        case .cexOperationFailed:
            placeValue = .fail
        default:
            placeValue = nil
        }

        if let placeValue {
            Analytics.log(
                event: .tokenButtonGoToProvider,
                params: [
                    .token: currentTokenItem.currencySymbol,
                    .place: placeValue.rawValue,
                ]
            )
        }

        openProvider()
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
