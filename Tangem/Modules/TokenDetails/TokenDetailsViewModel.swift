//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 09/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk
import TangemExpress

final class TokenDetailsViewModel: SingleTokenBaseViewModel, ObservableObject {
    @Injected(\.expressPendingTransactionsRepository) private var expressPendingTxRepository: ExpressPendingTransactionRepository

    @Published private var balance: LoadingValue<BalanceInfo> = .loading
    @Published var actionSheet: ActionSheetBinder?
    @Published var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []

    private(set) var balanceWithButtonsModel: BalanceWithButtonsViewModel!
    private(set) lazy var tokenDetailsHeaderModel: TokenDetailsHeaderViewModel = .init(tokenItem: tokenItem)

    private weak var coordinator: TokenDetailsRoutable?
    private let pendingExpressTransactionsManager: PendingExpressTransactionsManager

    private var bag = Set<AnyCancellable>()
    private var notificatioChangeSubscription: AnyCancellable?

    var tokenItem: TokenItem {
        switch amountType {
        case .token(let token):
            return .token(token, blockchain)
        default:
            return .blockchain(blockchain)
        }
    }

    var iconUrl: URL? {
        guard let id = tokenItem.id else {
            return nil
        }

        return TokenIconURLBuilder().iconURL(id: id)
    }

    var customTokenColor: Color? {
        tokenItem.token?.customTokenColor
    }

    var canHideToken: Bool { userWalletModel.isMultiWallet }

    init(
        cardModel: CardViewModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        notificationManager: NotificationManager,
        pendingExpressTransactionsManager: PendingExpressTransactionsManager,
        coordinator: TokenDetailsRoutable,
        tokenRouter: SingleTokenRoutable
    ) {
        self.coordinator = coordinator
        self.pendingExpressTransactionsManager = pendingExpressTransactionsManager
        super.init(
            userWalletModel: cardModel,
            walletModel: walletModel,
            exchangeUtility: exchangeUtility,
            notificationManager: notificationManager,
            tokenRouter: tokenRouter
        )
        notificationManager.setupManager(with: self)
        balanceWithButtonsModel = .init(balanceProvider: self, buttonsProvider: self)

        prepareSelf()
    }

    deinit {
        print("TokenDetailsViewModel deinit")
    }

    func onAppear() {
        Analytics.log(event: .detailsScreenOpened, params: [Analytics.ParameterKey.token: tokenItem.currencySymbol])
    }

    override func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .openFeeCurrency:
            openFeeCurrency()
        default:
            super.didTapNotificationButton(with: id, action: action)
        }
    }

    override func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        self.actionSheet = actionSheet
    }
}

// MARK: - Hide token

extension TokenDetailsViewModel {
    func hideTokenButtonAction() {
        if userWalletModel.userTokensManager.canRemove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath) {
            showHideWarningAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    private func showUnableToHideAlert() {
        let message = Localization.tokenDetailsUnableHideAlertMessage(
            currencySymbol,
            blockchain.displayName
        )

        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsUnableHideAlertTitle(currencySymbol),
            message: message,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }

    private func showHideWarningAlert() {
        alert = AlertBuilder.makeAlert(
            title: Localization.tokenDetailsHideAlertTitle(currencySymbol),
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.hideToken()
            },
            secondaryButton: .cancel()
        )
    }

    private func hideToken() {
        Analytics.log(
            event: .buttonRemoveToken,
            params: [
                Analytics.ParameterKey.token: currencySymbol,
                Analytics.ParameterKey.source: Analytics.ParameterValue.token.rawValue,
            ]
        )

        userWalletModel.userTokensManager.remove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath)
        dismiss()
    }
}

// MARK: - Setup functions

private extension TokenDetailsViewModel {
    private func prepareSelf() {
        updateBalance(walletModelState: walletModel.state)
        tokenNotificationInputs = notificationManager.notificationInputs
        bind()
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateBalance(walletModelState: newState)
            }
            .store(in: &bag)

        pendingExpressTransactionsManager.pendingTransactionsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, pendingTxs in
                let factory = PendingExpressTransactionsConverter()

                return factory.convertToTokenDetailsPendingTxInfo(
                    pendingTxs,
                    tapAction: weakify(viewModel, forFunction: TokenDetailsViewModel.didTapPendingExpressTransaction(with:))
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.pendingExpressTransactions, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateBalance(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created, .loading:
            balance = .loading
        case .idle, .noAccount:
            balance = .loaded(.init(
                balance: walletModel.balance,
                fiatBalance: walletModel.fiatBalance
            ))
        case .failed(let message):
            balance = .failedToLoad(error: message)
        case .noDerivation:
            // User can't reach this screen without derived keys
            balance = .failedToLoad(error: "")
        }
    }

    private func didTapPendingExpressTransaction(with id: String) {
        guard
            let pendingTransaction = pendingExpressTransactionsManager.pendingTransactions.first(where: { $0.transactionRecord.expressTransactionId == id })
        else {
            return
        }

        coordinator?.openPendingExpressTransactionDetails(
            for: pendingTransaction,
            tokenItem: tokenItem,
            pendingTransactionsManager: pendingExpressTransactionsManager
        )
    }
}

// MARK: - Navigation functions

private extension TokenDetailsViewModel {
    func dismiss() {
        coordinator?.dismiss()
    }

    func openFeeCurrency() {
        guard let feeCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(
            where: { $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork }
        ) else {
            assertionFailure("Fee currency '\(walletModel.feeTokenItem.name)' for currency '\(walletModel.tokenItem.name)' not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

extension TokenDetailsViewModel: BalanceProvider {
    var balancePublisher: AnyPublisher<LoadingValue<BalanceInfo>, Never> { $balance.eraseToAnyPublisher() }
}
