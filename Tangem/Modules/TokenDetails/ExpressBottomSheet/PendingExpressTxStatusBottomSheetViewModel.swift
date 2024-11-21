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

protocol PendingGenericTransactionsManager: AnyObject {
    var pendingGenericTransactions: [PendingTransaction] { get }
    var pendingGenericTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { get }

    func hideGenericTransaction(with id: String)
}

final class CompoundPendingGenericTransactionsManager: PendingGenericTransactionsManager {
    private let first: PendingGenericTransactionsManager
    private let second: PendingGenericTransactionsManager

    init(
        first: PendingGenericTransactionsManager,
        second: PendingGenericTransactionsManager
    ) {
        self.first = first
        self.second = second
    }

    var pendingGenericTransactions: [PendingTransaction] {
        first.pendingGenericTransactions + second.pendingGenericTransactions
    }

    var pendingGenericTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> {
        Publishers.CombineLatest(
            first.pendingGenericTransactionsPublisher,
            second.pendingGenericTransactionsPublisher
        )
        .map { $0 + $1 }
        .eraseToAnyPublisher()
    }

    func hideGenericTransaction(with id: String) {
        first.hideGenericTransaction(with: id)
        second.hideGenericTransaction(with: id)
    }
}

enum PendingTransactionFiatInfo {
    case string(String)
    case tokenTxInfo(ExpressPendingTransactionRecord.TokenTxInfo)
}

struct PendingTransaction {
    let branch: ExpressBranch

    let expressTransactionId: String
    let externalTxId: String?
    let externalTxURL: String?
    let provider: ExpressPendingTransactionRecord.Provider
    let date: Date

    let sourceTokenIconInfo: TokenIconInfo
    let sourceAmountText: String
    let sourceFiatInfo: PendingTransactionFiatInfo

    let destinationTokenIconInfo: TokenIconInfo
    let destinationAmountText: String
    let destinationFiatInfo: PendingTransactionFiatInfo

    let transactionStatus: PendingExpressTransactionStatus

    let refundedTokenItem: TokenItem?

    let statuses: [PendingExpressTransactionStatus]

    static func from(_ transaction: PendingExpressTransaction) -> PendingTransaction {
        let record = transaction.transactionRecord

        let iconInfoBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        let sourceTokenTxInfo = record.sourceTokenTxInfo
        let sourceTokenItem = sourceTokenTxInfo.tokenItem

        let destinationTokenTxInfo = record.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        return PendingTransaction(
            branch: .swap,
            expressTransactionId: record.expressTransactionId,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxURL,
            provider: record.provider,
            date: record.date,
            sourceTokenIconInfo: iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom),
            sourceAmountText: balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol),
            sourceFiatInfo: .tokenTxInfo(record.sourceTokenTxInfo),
            destinationTokenIconInfo: iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom),
            destinationAmountText: balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol),
            destinationFiatInfo: .tokenTxInfo(record.destinationTokenTxInfo),
            transactionStatus: record.transactionStatus,
            refundedTokenItem: record.refundedTokenItem,
            statuses: transaction.statuses
        )
    }

    static func from(_ transaction: PendingOnrampTransaction) -> PendingTransaction {
        let record = transaction.transactionRecord

        let iconInfoBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        let sourceAmountText = balanceFormatter.formatFiatBalance(
            record.fromAmount,
            currencyCode: record.fromCurrencyCode
        )

        let destinationTokenTxInfo = record.destinationTokenTxInfo
        let destinationTokenItem = destinationTokenTxInfo.tokenItem

        return PendingTransaction(
            branch: .onramp,
            expressTransactionId: record.expressTransactionId,
            externalTxId: record.externalTxId,
            externalTxURL: record.externalTxURL,
            provider: record.provider,
            date: record.date,
            sourceTokenIconInfo: iconInfoBuilder.build(from: record.fromCurrencyCode),
            sourceAmountText: sourceAmountText,
            sourceFiatInfo: .string(sourceAmountText),
            destinationTokenIconInfo: iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom),
            destinationAmountText: balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol),
            destinationFiatInfo: .tokenTxInfo(destinationTokenTxInfo),
            transactionStatus: record.transactionStatus,
            refundedTokenItem: nil,
            statuses: transaction.statuses
        )
    }
}

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
    private weak var pendingTransactionsManager: (any PendingGenericTransactionsManager)?

    private let pendingTransaction: PendingTransaction
    private let currentTokenItem: TokenItem

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
        pendingTransactionsManager: PendingGenericTransactionsManager,
        router: PendingExpressTxStatusRoutable
    ) {
        self.pendingTransaction = pendingTransaction
        self.currentTokenItem = currentTokenItem
        self.pendingTransactionsManager = pendingTransactionsManager
        self.router = router

        let provider = pendingTransaction.provider

        switch pendingTransaction.branch {
        case .swap:
            sheetTitle = Localization.expressExchangeStatusTitle
            statusViewTitle = Localization.expressExchangeBy(provider.name)
        case .onramp:
            sheetTitle = Localization.commonTransactionStatus
            statusViewTitle = Localization.commonTransactionStatus
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

        sourceTokenIconInfo = pendingTransaction.sourceTokenIconInfo
        sourceAmountText = pendingTransaction.sourceAmountText

//        if let expressSpecific = pendingTransaction.transactionRecord.expressSpecific {
//            let sourceTokenTxInfo = expressSpecific.sourceTokenTxInfo
//            let sourceTokenItem = sourceTokenTxInfo.tokenItem
//            sourceTokenIconInfo = iconInfoBuilder.build(from: sourceTokenItem, isCustom: sourceTokenTxInfo.isCustom)
//            sourceAmountText = balanceFormatter.formatCryptoBalance(sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol)
//        } else if let onrampSpecific = pendingTransaction.transactionRecord.onrampSpecific {
//            sourceTokenIconInfo = iconInfoBuilder.build(from: onrampSpecific.fromCurrencyCode)
//            sourceAmountText = balanceFormatter.formatFiatBalance(
//                onrampSpecific.fromAmount,
//                currencyCode: onrampSpecific.fromCurrencyCode
//            )
//        } else {
//            fatalError("unexpected state")
//        }

//        let destinationTokenTxInfo = pendingTransaction.transactionRecord.destinationTokenTxInfo
//        let destinationTokenItem = destinationTokenTxInfo.tokenItem
//
//        destinationTokenIconInfo = iconInfoBuilder.build(from: destinationTokenItem, isCustom: destinationTokenTxInfo.isCustom)
//        destinationAmountText = balanceFormatter.formatCryptoBalance(destinationTokenTxInfo.amount, currencyCode: destinationTokenItem.currencySymbol)

        destinationTokenIconInfo = pendingTransaction.destinationTokenIconInfo
        destinationAmountText = pendingTransaction.destinationAmountText

        loadEmptyFiatRates()
        updateUI(with: pendingTransaction, delay: 0)
        bind()
    }

    func onAppear() {
        Analytics.log(
            event: .tokenSwapStatusScreenOpened,
            params: [
                .token: currentTokenItem.currencySymbol,
                .provider: pendingTransaction.provider.name,
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
        switch pendingTransaction.sourceFiatInfo {
        case .string(let text):
            sourceFiatAmountTextState = .loaded(text: text)
        case .tokenTxInfo(let tokenTxInfo):
            loadRatesIfNeeded(stateKeyPath: \.sourceFiatAmountTextState, for: tokenTxInfo, on: self)
        }

        switch pendingTransaction.destinationFiatInfo {
        case .string(let text):
            destinationFiatAmountTextState = .loaded(text: text)
        case .tokenTxInfo(let tokenTxInfo):
            loadRatesIfNeeded(stateKeyPath: \.destinationFiatAmountTextState, for: tokenTxInfo, on: self)
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
        subscription = pendingTransactionsManager?.pendingGenericTransactionsPublisher
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
                if pendingTx.transactionStatus.isTerminated, pendingTx.refundedTokenItem == nil {
                    viewModel.hidePendingTx(expressTransactionId: pendingTx.expressTransactionId)
                }

                viewModel.updateUI(with: pendingTx, delay: Constants.notificationAnimationDelay)
            }
    }

    private func hidePendingTx(expressTransactionId: String) {
        pendingTransactionsManager?.hideGenericTransaction(with: expressTransactionId)
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
