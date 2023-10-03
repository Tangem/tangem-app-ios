//
//  SingleTokenBaseViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 07/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemSdk
import BlockchainSdk
import TangemSwapping
import CombineExt

class SingleTokenBaseViewModel: NotificationTapDelegate {
    @Published var alert: AlertBinder? = nil
    @Published var transactionHistoryState: TransactionsListView.State = .loading
    @Published var isReloadingTransactionHistory: Bool = false
    @Published var actionButtons: [ButtonWithIconInfo] = []
    @Published private(set) var tokenNotificationInputs: [NotificationViewInput] = []

    lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()

    let swappingUtils = SwappingAvailableUtils()
    let exchangeUtility: ExchangeCryptoUtility
    let notificationManager: NotificationManager

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel

    var availableActions: [TokenActionType] = []

    private let tokenRouter: SingleTokenRoutable

    private var isSwapAvailable = false
    private var percentFormatter = PercentFormatter()
    private var transactionHistoryBag: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    var canSend: Bool {
        guard userWalletModel.config.hasFeature(.send) else {
            return false
        }

        return walletModel.canSendTransaction
    }

    var blockchainNetwork: BlockchainNetwork { walletModel.blockchainNetwork }

    var amountType: Amount.AmountType { walletModel.amountType }

    var rateFormatted: String { walletModel.rateFormatted }

    var priceChangeState: TokenPriceChangeView.State {
        guard let quote = walletModel.quote else {
            return .noData
        }

        let signType = ChangeSignType(from: quote.change)
        let percent = percentFormatter.percentFormat(value: quote.change)
        return .loaded(signType: signType, text: percent)
    }

    var blockchain: Blockchain { blockchainNetwork.blockchain }

    var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    var isMarketPriceAvailable: Bool {
        if case .token(let token) = amountType {
            return token.id != nil
        } else {
            return true
        }
    }

    lazy var transactionHistoryMapper: TransactionHistoryMapper = .init(currencySymbol: currencySymbol, walletAddress: walletModel.defaultAddress)

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        exchangeUtility: ExchangeCryptoUtility,
        notificationManager: NotificationManager,
        tokenRouter: SingleTokenRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.exchangeUtility = exchangeUtility
        self.notificationManager = notificationManager
        self.tokenRouter = tokenRouter

        prepareSelf()
    }

    func presentActionSheet(_ actionSheet: ActionSheetBinder) {
        assertionFailure("Must be reimplemented")
    }

    func openExplorer() {
        let addresses = walletModel.wallet.addresses

        if addresses.count == 1 {
            openAddressExplorer(at: 0)
        } else {
            openAddressSelector(addresses) { [weak self] index in
                self?.openAddressExplorer(at: index)
            }
        }
    }

    func openTransactionExplorer(transaction hash: String) {
        guard let url = walletModel.exploreTransactionURL(for: hash) else {
            return
        }

        openExplorer(at: url)
    }

    func fetchMoreHistory() -> FetchMore? {
        guard let transactionHistoryService = walletModel.transactionHistoryService,
              transactionHistoryService.canFetchMore else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.loadHistory()
        }
    }

    func reloadHistory() {
        Analytics.log(event: .buttonReload, params: [.token: currencySymbol])

        // We should reset transaction history to initial state here
        walletModel.transactionHistoryService?.reset()

        DispatchQueue.main.async {
            self.isReloadingTransactionHistory = true
        }

        loadHistory()
    }

    func loadHistory() {
        transactionHistoryBag = walletModel
            .updateTransactionsHistory()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] _ in
                self?.isReloadingTransactionHistory = false
            }
    }

    // We need to keep this not in extension because we may want to override this logic and
    // implementation from extensions can't be overriden
    func didTapNotification(with id: NotificationViewId) {}

    // We need to keep this not in extension because we may want to override this logic and
    // implementation from extensions can't be overriden
    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .buyCrypto:
            openBuyCryptoIfPossible()
        default:
            break
        }
    }

    private func openAddressExplorer(at index: Int) {
        guard let url = walletModel.exploreURL(for: index, token: amountType.token) else {
            return
        }

        openExplorer(at: url)
    }
}

// MARK: - Setup functions

extension SingleTokenBaseViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        loadSwappingState()
        updateActionButtons()
        loadHistory()
    }

    private func setupActionButtons() {
        let listBuilder = TokenActionListBuilder()
        let canShowSwap = userWalletModel.config.hasFeature(.swapping)
        availableActions = listBuilder.buildActionsForButtonsList(canShowSwap: canShowSwap)
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] newState in
                AppLog.shared.debug("Token details receive new wallet model state: \(newState)")
                self?.updateActionButtons()
            }
            .store(in: &bag)

        walletModel.transactionHistoryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                AppLog.shared.debug("New transaction history state: \(newState)")
                self?.updateHistoryState(to: newState)
            }
            .store(in: &bag)

        notificationManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.tokenNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let isDisabled = isButtonDisabled(with: type)

            return ButtonWithIconInfo(title: type.title, icon: type.icon, action: { [weak self] in
                self?.action(for: type)?()
            }, disabled: isDisabled)
        }

        actionButtons = buttons.sorted(by: { lhs, rhs in
            if !lhs.disabled, !rhs.disabled {
                return false
            }

            return !lhs.disabled
        })
    }

    private func updateHistoryState(to newState: WalletModel.TransactionHistoryState) {
        switch newState {
        case .notSupported:
            transactionHistoryState = .notSupported
        case .notLoaded:
            transactionHistoryState = .loading
        case .loading:
            if case .notLoaded = newState {
                transactionHistoryState = .loading
            }
        case .error(let error):
            transactionHistoryState = .error(error)
        case .loaded(let records):
            let listItems = transactionHistoryMapper.mapTransactionListItem(from: records)
            transactionHistoryState = .loaded(listItems)
        }
    }

    private func loadSwappingState() {
        guard userWalletModel.config.isFeatureVisible(.swapping) else {
            return
        }

        var swappingSubscription: AnyCancellable?
        swappingSubscription = swappingUtils
            .canSwapPublisher(amountType: amountType, blockchain: blockchain)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                AppLog.shared.debug("Load swapping availability state completion: \(completion)")
                withExtendedLifetime(swappingSubscription) {}
            } receiveValue: { [weak self] isSwapAvailable in
                self?.isSwapAvailable = isSwapAvailable
                self?.updateActionButtons()
            }
    }

    private func isButtonDisabled(with type: TokenActionType) -> Bool {
        let canExchange = userWalletModel.config.isFeatureVisible(.exchange)
        switch type {
        case .buy:
            return !(canExchange && exchangeUtility.buyAvailable)
        case .send:
            return !canSend
        case .receive:
            return false
        case .exchange:
            return !isSwapAvailable
        case .sell:
            return !(canExchange && exchangeUtility.sellAvailable)
        case .copyAddress, .hide:
            return true
        }
    }

    private func action(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .buy: return openBuyCryptoIfPossible
        case .send: return openSend
        case .receive: return openReceive
        case .exchange: return openExchange
        case .sell: return openSell
        case .copyAddress, .hide: return nil
        }
    }
}

// MARK: - Navigation

extension SingleTokenBaseViewModel {
    func openReceive() {
        tokenRouter.openReceive(walletModel: walletModel)
    }

    func openBuyCryptoIfPossible() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        tokenRouter.openBuyCryptoIfPossible(walletModel: walletModel)
    }

    func openSend() {
        tokenRouter.openSend(walletModel: walletModel)
    }

    func openExchange() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        tokenRouter.openExchange(walletModel: walletModel)
    }

    func openSell() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        tokenRouter.openSell(for: walletModel)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        tokenRouter.openSendToSell(with: request, for: walletModel)
    }

    func openAddressSelector(_ addresses: [BlockchainSdk.Address], callback: @escaping (Int) -> Void) {
        if addresses.isEmpty {
            return
        }

        let addressButtons: [Alert.Button] = addresses.enumerated().map { index, address in
            .default(Text(address.localizedName)) {
                callback(index)
            }
        }

        let sheet = ActionSheet(
            title: Text(Localization.tokenDetailsChooseAddress),
            buttons: addressButtons + [.cancel(Text(Localization.commonCancel))]
        )
        presentActionSheet(ActionSheetBinder(sheet: sheet))
    }

    func openExplorer(at url: URL) {
        tokenRouter.openExplorer(at: url, for: walletModel)
    }
}

extension SingleTokenBaseViewModel: ActionButtonsProvider {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { $actionButtons.eraseToAnyPublisher() }
}
