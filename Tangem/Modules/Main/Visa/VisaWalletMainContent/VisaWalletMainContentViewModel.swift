//
//  VisaWalletMainContentViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 13/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemVisa

protocol VisaWalletRoutable: AnyObject {
    func openReceiveScreen(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo])
    func openInSafari(url: URL)
    func openTransactionDetails(tokenItem: TokenItem, for record: VisaTransactionRecord)
}

class VisaWalletMainContentViewModel: ObservableObject {
    @Published var balancesAndLimitsViewModel: VisaBalancesLimitsBottomSheetViewModel? = nil

    @Published private(set) var transactionListViewState: TransactionsListView.State = .loading
    @Published private(set) var isTransactoinHistoryReloading: Bool = true
    @Published private(set) var cryptoLimitText: String = ""
    @Published private(set) var numberOfDaysLimitText: String = ""
    @Published private(set) var notificationInputs: [NotificationViewInput] = []
    @Published private(set) var failedToLoadInfoNotificationInput: NotificationViewInput?

    var isBalancesAndLimitsBlockLoading: Bool {
        cryptoLimitText.isEmpty || numberOfDaysLimitText.isEmpty
    }

    private let visaWalletModel: VisaWalletModel
    private weak var coordinator: VisaWalletRoutable?

    private var bag = Set<AnyCancellable>()
    private var updateTask: Task<Void, Error>?

    init(
        visaWalletModel: VisaWalletModel,
        coordinator: VisaWalletRoutable?
    ) {
        self.visaWalletModel = visaWalletModel
        self.coordinator = coordinator

        bind()
    }

    func openDeposit() {
        guard let tokenItem = visaWalletModel.tokenItem else {
            return
        }

        Analytics.log(event: .buttonReceive, params: [.token: tokenItem.currencySymbol])

        let addressType = AddressType.default
        let addressInfo = ReceiveAddressInfo(
            address: visaWalletModel.accountAddress,
            type: addressType,
            localizedName: addressType.defaultLocalizedName,
            addressQRImage: QrCodeGenerator.generateQRCode(from: visaWalletModel.accountAddress)
        )
        coordinator?.openReceiveScreen(
            tokenItem: tokenItem,
            addressInfos: [addressInfo]
        )
    }

    func openBalancesAndLimits() {
        guard
            let balances = visaWalletModel.balances,
            let limit = visaWalletModel.limits?.currentLimit,
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        balancesAndLimitsViewModel = .init(balances: balances, limit: limit, currencySymbol: tokenItem.currencySymbol)
    }

    func openExplorer() {
        guard let url = visaWalletModel.exploreURL() else {
            return
        }

        coordinator?.openInSafari(url: url)
    }

    func exploreTransaction(with id: String) {
        guard
            let transactionId = UInt64(id),
            let transactionRecord = visaWalletModel.transaction(with: transactionId),
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        coordinator?.openTransactionDetails(tokenItem: tokenItem, for: transactionRecord)
        VisaLogger.info("[Visa Main Content View Model] Explore transaction with id: \(transactionId)")
    }

    func reloadTransactionHistory() {
        isTransactoinHistoryReloading = true
        visaWalletModel.reloadHistory()
    }

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        guard visaWalletModel.canFetchMoreTransactionHistory else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.visaWalletModel.loadNextHistoryPage()
        }
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateTask == nil else {
            return
        }

        isTransactoinHistoryReloading = true
        updateTask = Task { [weak self] in
            await self?.visaWalletModel.generalUpdateAsync()
            try await Task.sleep(seconds: 0.2)

            await runOnMain {
                self?.isTransactoinHistoryReloading = false
                completionHandler()
            }

            self?.updateTask = nil
        }
    }

    private func bind() {
        visaWalletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { (self, newState) in
                switch newState {
                case .loading, .notInitialized:
                    return
                case .idle:
                    self.updateLimits()
                case .failedToInitialize(let error):
                    self.failedToLoadInfoNotificationInput = NotificationsFactory().buildNotificationInput(for: error.notificationEvent)
                }
            }
            .store(in: &bag)

        visaWalletModel.transactionHistoryStatePublisher
            .receive(on: DispatchQueue.main)
            .filter { !$0.isLoading }
            .withWeakCaptureOf(self)
            .map { viewModel, newState in
                switch newState {
                case .initial, .loading:
                    return .loading
                case .loaded:
                    viewModel.isTransactoinHistoryReloading = false
                    return .loaded(viewModel.visaWalletModel.transactionHistoryItems)
                case .failedToLoad(let error):
                    viewModel.isTransactoinHistoryReloading = false
                    return .error(error)
                }
            }
            .assign(to: \.transactionListViewState, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateLimits() {
        guard
            let limits = visaWalletModel.limits,
            let tokenItem = visaWalletModel.tokenItem
        else {
            return
        }

        let balanceFormatter = BalanceFormatter()
        let currentLimit = limits.currentLimit
        let remainingSummary = currentLimit.remainingOTPAmount ?? 0
        cryptoLimitText = balanceFormatter.formatCryptoBalance(remainingSummary, currencyCode: tokenItem.currencySymbol)

        let remainingTimeSeconds = Date().distance(to: currentLimit.actualExpirationDate)
        let remainingDays = Int(remainingTimeSeconds / 3600 / 24)
        numberOfDaysLimitText = "available for \(remainingDays) day(s)"
    }
}
