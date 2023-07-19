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
    @Published var selectedAddressIndex: Int = 0
    var singleWalletModel: WalletModel

    var balanceViewModel: BalanceViewModel? {
        let tokenModel = walletModelsManager.walletModels.first(where: { !$0.isMainToken })
            .map {
                TokenBalanceViewModel(
                    name: $0.name,
                    balance: $0.balance,
                    fiatBalance: $0.fiatBalance
                )
            }

        return BalanceViewModel(
            hasTransactionInProgress: singleWalletModel.hasPendingTx,
            state: singleWalletModel.state,
            name: singleWalletModel.name,
            fiatBalance: singleWalletModel.fiatBalance,
            balance: singleWalletModel.balance,
            tokenBalanceViewModel: tokenModel
        )
    }

    var pendingTransactionViews: [LegacyPendingTxView] {
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

    public var canSend: Bool {
        return singleWalletModel.wallet.canSend(amountType: .coin)
    }

    private let totalSumBalanceViewModel: TotalSumBalanceViewModel
    private let walletModelsManager: WalletModelsManager
    private unowned let output: LegacySingleWalletContentViewModelOutput
    private var bag = Set<AnyCancellable>()

    init(
        walletModel: WalletModel,
        walletModelsManager: WalletModelsManager,
        totalBalanceProvider: TotalBalanceProviding,
        output: LegacySingleWalletContentViewModelOutput
    ) {
        self.walletModelsManager = walletModelsManager
        self.output = output

        totalSumBalanceViewModel = .init(
            totalBalanceProvider: totalBalanceProvider,
            walletModelsManager: walletModelsManager,
            tapOnCurrencySymbol: output
        )

        /// Initial set to `singleWalletModel`
        singleWalletModel = walletModel

        bind()
    }

    func onRefresh(done: @escaping () -> Void) {
        walletModelsManager.updateAll(silent: false, completion: done)
    }

    func openQR() {
        let shareAddress = singleWalletModel.shareAddressString(for: selectedAddressIndex)
        let address = singleWalletModel.displayAddress(for: selectedAddressIndex)
        let qrNotice = singleWalletModel.qrReceiveMessage

        output.openQR(shareAddress: shareAddress, address: address, qrNotice: qrNotice)
        Analytics.log(.tokenButtonShowTheWalletAddress)
    }

    func showExplorerURL(url: URL?) {
        output.showExplorerURL(url: url, walletModel: singleWalletModel)
    }

    func copyAddress() {
        Analytics.log(.buttonCopyAddress)
        UIPasteboard.general.string = singleWalletModel.displayAddress(for: selectedAddressIndex)
    }

    private func bind() {
        singleWalletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] publish in
                self?.objectWillChange.send()
            })
            .store(in: &bag)

        singleWalletModel.walletDidChangePublisher
            .filter { $0.isSuccesfullyLoaded }
            .sink { [weak self] state in
                guard let self else {
                    return
                }

                Analytics.logTopUpIfNeeded(balance: self.singleWalletModel.fiatValue ?? 0)
            }
            .store(in: &bag)
    }
}
