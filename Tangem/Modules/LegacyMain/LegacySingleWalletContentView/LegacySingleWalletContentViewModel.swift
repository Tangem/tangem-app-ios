//
//  SingleWalletContentViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import class UIKit.UIPasteboard
import BlockchainSdk

protocol LegacySingleWalletContentViewModelOutput: OpenCurrencySelectionDelegate {
    func openPushTx(for index: Int, walletModel: WalletModel)
    func openQR(shareAddress: String, address: String, qrNotice: String)
    func openBuyCrypto()
    func showExplorerURL(url: URL?, walletModel: WalletModel)
}

class LegacySingleWalletContentViewModel: ObservableObject {
    @Injected(\.exchangeService) var exchangeService: ExchangeService

    @Published var selectedAddressIndex: Int = 0
    @Published var singleWalletModel: WalletModel?
    @Published var totalBalanceButtons = [ButtonWithIconInfo]()
    @Published var transactionHistoryState = TransactionsListView.State.loading

    var pendingTransactionViews: [LegacyPendingTxView] {
        guard let singleWalletModel else { return [] }

        let incTxViews = singleWalletModel.incomingPendingTransactions
            .map { LegacyPendingTxView(pendingTx: $0) }

        let outgTxViews = singleWalletModel.outgoingPendingTransactions
            .enumerated()
            .map { index, pendingTx -> LegacyPendingTxView in
                LegacyPendingTxView(pendingTx: pendingTx) { [weak self] in
                    if let singleWalletModel = self?.singleWalletModel {
                        self?.output.openPushTx(for: index, walletModel: singleWalletModel)
                    }
                }
            }

        return incTxViews + outgTxViews
    }

    var canShowAddress: Bool {
        cardModel.canShowAddress
    }

    var canShowTransactionHistory: Bool {
        cardModel.canShowTransactionHistory
    }

    public var canSend: Bool {
        guard cardModel.canSend else {
            return false
        }

        return singleWalletModel?.wallet.canSend(amountType: .coin) ?? false
    }

    lazy var totalSumBalanceViewModel = TotalSumBalanceViewModel(
        userWalletModel: cardModel,
        cardAmountType: cardModel.cardAmountType,
        tapOnCurrencySymbol: output
    )

    private let cardModel: CardViewModel
    private unowned let output: LegacySingleWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()
    private var transactionHistoryLoaderSubscription: AnyCancellable?

    private var exchangeServiceInitialized = false

    init(
        cardModel: CardViewModel,
        output: LegacySingleWalletContentViewModelOutput
    ) {
        self.cardModel = cardModel
        self.output = output

        /// Initial set to `singleWalletModel`
        singleWalletModel = cardModel.walletModels.first

        makeActionButtons()
        bind()
    }

    func onRefresh(done: @escaping () -> Void) {
        cardModel.updateAndReloadWalletModels(completion: done)
    }

    func openQR() {
        guard let walletModel = singleWalletModel else { return }

        let shareAddress = walletModel.shareAddressString(for: selectedAddressIndex)
        let address = walletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = walletModel.getQRReceiveMessage()

        output.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
        Analytics.log(.tokenButtonShowTheWalletAddress)
    }

    func showExplorerURL(url: URL?) {
        guard let walletModel = singleWalletModel else { return }

        output.showExplorerURL(url: url, walletModel: walletModel)
    }

    func copyAddress() {
        Analytics.log(.buttonCopyAddress)
        if let walletModel = singleWalletModel {
            UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex)
        }
    }

    private func bind() {
        /// Subscribe for update `singleWalletModel` for each changes in `WalletModel`
        cardModel.subscribeToWalletModels()
            .map { walletModels in
                walletModels
                    .map { $0.objectWillChange }
                    .combineLatest()
                    .map { _ in walletModels }
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletModels in
                self?.singleWalletModel = walletModels.first
            }
            .store(in: &bag)

        /// Subscription to handle transaction updates, such as new transactions from send screen.
        cardModel.subscribeToWalletModels()
            .map { walletModels in
                walletModels
                    .map { $0.walletManager.walletPublisher }
                    .combineLatest()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] publish in
                self?.objectWillChange.send()
            })
            .store(in: &bag)

        singleWalletModel?.$state
            .filter { $0.isSuccesfullyLoaded }
            .delay(for: 0.5, scheduler: DispatchQueue.main) // workaround willChange issue
            .sink { [weak self] state in
                guard
                    let self,
                    let singleWalletModel = self.singleWalletModel
                else {
                    return
                }

                let balance = singleWalletModel.totalBalance
                Analytics.logTopUpIfNeeded(balance: balance)
            }
            .store(in: &bag)

        if canShowTransactionHistory {
            singleWalletModel?.$transactionHistoryState
                .sink(receiveValue: { [weak self] state in
                    self?.updateTransactionHistoryState(state)
                })
                .store(in: &bag)
        }

        if !canShowAddress {
            exchangeService.initializationPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] exchangeServiceInitialized in
                    guard exchangeServiceInitialized else {
                        return
                    }

                    self?.exchangeServiceInitialized = exchangeServiceInitialized
                    self?.makeActionButtons()
                }
                .store(in: &bag)
        }
    }

    private func makeActionButtons() {
        if canShowAddress {
            return
        }

        guard
            let walletModel = singleWalletModel,
            let token = walletModel.getTokens().first,
            exchangeServiceInitialized,
            exchangeService.canBuy(
                token.symbol,
                amountType: .token(value: token),
                blockchain: walletModel.blockchainNetwork.blockchain
            )
        else {
            return
        }

        totalBalanceButtons = [
            .init(
                title: Localization.commonBuy,
                icon: Assets.plusMini,
                action: { [weak self] in
                    Analytics.log(.buttonBuy)
                    self?.output.openBuyCrypto()
                }
            ),
        ]
    }

    private func updateTransactionHistoryState(_ newState: WalletModel.TransactionHistoryState) {
        switch newState {
        case .notSupported, .loading:
            break
        case .notLoaded:
            transactionHistoryState = .loading
        case .failedToLoad(let error):
            transactionHistoryState = .error(error)
        case .loaded:
            updateTransactionHistoryList()
        }
    }

    private func updateTransactionHistoryList() {
        guard
            canShowTransactionHistory,
            let singleWalletModel = singleWalletModel
        else {
            return
        }

        let txListItems = TransactionHistoryMapper().makeTransactionListItems(from: singleWalletModel.transactions)
        transactionHistoryState = .loaded(txListItems)
    }
}
