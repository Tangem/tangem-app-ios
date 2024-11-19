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
import BlockchainSdk
import TangemFoundation

class SingleTokenBaseViewModel: NotificationTapDelegate {
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    @Published var alert: AlertBinder? = nil
    @Published var transactionHistoryState: TransactionsListView.State = .loading
    @Published var isReloadingTransactionHistory: Bool = false
    @Published var actionButtons: [FixedSizeButtonWithIconInfo] = []
    @Published var tokenNotificationInputs: [NotificationViewInput] = []
    @Published private(set) var pendingTransactionViews: [TransactionViewModel] = []
    @Published private(set) var miniChartData: LoadingValue<[Double]?> = .loading

    let exchangeUtility: ExchangeCryptoUtility
    let notificationManager: NotificationManager

    let userWalletModel: UserWalletModel
    let walletModel: WalletModel

    var availableActions: [TokenActionType] = []

    private let tokenRouter: SingleTokenRoutable
    private let priceFormatter = MarketsTokenPriceFormatter()

    private var priceChangeFormatter = PriceChangeFormatter()
    private var transactionHistoryBag: AnyCancellable?
    private var updateSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    var blockchainNetwork: BlockchainNetwork { walletModel.blockchainNetwork }

    var amountType: Amount.AmountType { walletModel.amountType }

    var rateFormatted: String {
        priceFormatter.formatPrice(walletModel.quote?.price)
    }

    var priceChangeState: TokenPriceChangeView.State {
        guard let change = walletModel.quote?.priceChange24h else {
            return .noData
        }

        let result = priceChangeFormatter.formatPercentValue(change, option: .priceChange)
        return .loaded(signType: result.signType, text: result.formattedText)
    }

    var blockchain: Blockchain { blockchainNetwork.blockchain }

    var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    var isMarketsDetailsAvailable: Bool {
        walletModel.tokenItem.id != nil
    }

    lazy var transactionHistoryMapper = TransactionHistoryMapper(currencySymbol: currencySymbol, walletAddresses: walletModel.wallet.addresses.map { $0.value }, showSign: true)
    lazy var pendingTransactionRecordMapper = PendingTransactionRecordMapper(formatter: BalanceFormatter())
    lazy var miniChartsProvider = MarketsListChartsHistoryProvider()

    private let miniChartPriceIntervalType = MarketsPriceIntervalType.day

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
        // flag isReloadingTransactionHistory need for locked fetchMore requests update transaction history, when pullToRefresh is active
        guard walletModel.canFetchHistory, !isReloadingTransactionHistory else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.performLoadHistory()
        }
    }

    func onPullToRefresh(completionHandler: @escaping RefreshCompletionHandler) {
        guard updateSubscription == nil else {
            return
        }

        if let id = walletModel.tokenItem.currencyId, miniChartsProvider.items.isEmpty {
            miniChartsProvider.fetch(for: [id], with: miniChartPriceIntervalType)
        }

        isReloadingTransactionHistory = true
        updateSubscription = walletModel.generalUpdate(silent: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self else {
                    return
                }

                AppLog.shared.debug("♻️ \(self) loading state changed")
                isReloadingTransactionHistory = false
                updateSubscription = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    completionHandler()
                }
            })
    }

    /// This method should be overridden to send analytics events for navigation.
    /// Please check `SingleWalletMainContentViewModel` and `TokenDetailsViewModel`
    func openMarketsTokenDetails() {
        tokenRouter.openMarketsTokenDetails(for: walletModel.tokenItem)
    }

    func onButtonReloadHistory() {
        Analytics.log(event: .buttonReload, params: [.token: currencySymbol])

        // We should reset transaction history to initial state here
        walletModel.clearHistory()

        DispatchQueue.main.async {
            self.isReloadingTransactionHistory = true
        }

        performLoadHistory()
    }

    func copyDefaultAddress() {
        UIPasteboard.general.string = walletModel.defaultAddress
        let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpactGenerator.impactOccurred()
    }

    // We need to keep this not in extension because we may want to override this logic and
    // implementation from extensions can't be overridden
    func didTapNotification(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .buyCrypto:
            openBuyCryptoIfPossible()
        case .addHederaTokenAssociation:
            fulfillAssetRequirements()
        case .stake:
            openStaking()
        case .empty:
            break
        default:
            break
        }
    }

    private func performLoadHistory() {
        transactionHistoryBag = walletModel
            .updateTransactionsHistory()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] _ in
                self?.isReloadingTransactionHistory = false
            }
    }

    private func fulfillAssetRequirements() {
        func sendAnalytics(isSuccessful: Bool) {
            let status: Analytics.ParameterValue = isSuccessful ? .sent : .error

            Analytics.log(
                event: .buttonAddTokenTrustline,
                params: [
                    .token: walletModel.tokenItem.currencySymbol,
                    .blockchain: blockchain.displayName,
                    .status: status.rawValue,
                ]
            )
        }

        let alertBuilder = SingleTokenAlertBuilder()
        let requirementsCondition = walletModel.assetRequirementsManager?.requirementsCondition(for: amountType)

        if let fulfillAssetRequirementsAlert = alertBuilder.fulfillAssetRequirementsAlert(
            for: requirementsCondition,
            feeTokenItem: walletModel.feeTokenItem,
            hasFeeCurrency: walletModel.feeCurrencyHasPositiveBalance
        ) {
            sendAnalytics(isSuccessful: false)
            alert = fulfillAssetRequirementsAlert

            return
        }

        sendAnalytics(isSuccessful: true)

        walletModel
            .fulfillRequirements(signer: userWalletModel.signer)
            .materialize()
            .failures()
            .withWeakCaptureOf(self)
            .map { viewModel, error in
                let alertBuilder = SingleTokenAlertBuilder()
                let networkName = viewModel.blockchain.displayName

                return alertBuilder.fulfillmentAssetRequirementsFailedAlert(error: error, networkName: networkName)
            }
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - Setup functions

extension SingleTokenBaseViewModel {
    private func prepareSelf() {
        bind()
        setupActionButtons()
        setupMiniChart()
        updateActionButtons()
        updatePendingTransactionView()
        performLoadHistory()
    }

    private func setupActionButtons() {
        guard TokenInteractionAvailabilityProvider(walletModel: walletModel).isActionButtonsAvailable() else {
            return
        }

        let listBuilder = TokenActionListBuilder()
        let canShowSwap = userWalletModel.config.isFeatureVisible(.swapping)
        let canShowBuySell = userWalletModel.config.isFeatureVisible(.exchange)
        availableActions = listBuilder.buildActionsForButtonsList(canShowBuySell: canShowBuySell, canShowSwap: canShowSwap)
    }

    private func bind() {
        walletModel.walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.updatePendingTransactionView()
            })
            .removeDuplicates()
            .filter { $0 != .loading }
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
            // Fix for reappearing banner notifications.
            // TODO: Refactor in IOS-5470
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .assign(to: \.tokenNotificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        walletModel.actionsUpdatePublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateActionButtons()
            }
            .store(in: &bag)
    }

    private func setupMiniChart() {
        guard let id = walletModel.tokenItem.currencyId else {
            miniChartData = .failedToLoad(error: "")
            return
        }
        miniChartsProvider.fetch(for: [id], with: miniChartPriceIntervalType)

        miniChartsProvider.$items
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .compactMap { viewModel, items in
                items[id]?[viewModel.miniChartPriceIntervalType]
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, chartsData in
                viewModel.updateMiniChartState(using: chartsData)
            }
            .store(in: &bag)
    }

    private func updatePendingTransactionView() {
        // Only if the transaction history isn't supported
        guard !walletModel.isSupportedTransactionHistory else {
            pendingTransactionViews = []
            return
        }

        pendingTransactionViews = walletModel.pendingTransactions.map { transaction in
            pendingTransactionRecordMapper.mapToTransactionViewModel(transaction)
        }
    }

    private func updateActionButtons() {
        let buttons = availableActions.map { type in
            let isDisabled = isButtonDisabled(with: type)

            return FixedSizeButtonWithIconInfo(
                title: type.title,
                icon: type.icon,
                disabled: false,
                style: isDisabled ? .disabled : .default,
                action: { [weak self] in
                    self?.action(for: type)?()
                },
                longPressAction: longTapAction(for: type)
            )
        }

        actionButtons = buttons.sorted(by: { lhs, rhs in
            if lhs.style != .disabled, rhs.style != .disabled {
                return false
            }

            return lhs.style != .disabled
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

    private func updateMiniChartState(using data: MarketsChartModel) {
        do {
            let mapper = MarketsTokenHistoryChartMapper()

            let chartPoints = try mapper
                .mapAndSortValues(from: data)
                .map(\.price.doubleValue)
            miniChartData = .loaded(chartPoints)
        } catch {
            AppLog.shared.error(error)
            miniChartData = .failedToLoad(error: error)
        }
    }

    private func isButtonDisabled(with type: TokenActionType) -> Bool {
        switch type {
        case .buy:
            return !exchangeUtility.buyAvailable
        case .send:
            return sendIsDisabled()
        case .receive:
            return isReceiveDisabled()
        case .exchange:
            return isSwapDisabled()
        case .sell:
            return sendIsDisabled() || !exchangeUtility.sellAvailable
        case .copyAddress, .hide, .stake, .marketsDetails:
            return true
        }
    }

    private func action(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .buy: return openBuyCryptoIfPossible
        case .send: return openSend
        case .receive: return openReceive
        case .exchange: return openExchangeAndLogAnalytics
        case .sell: return openSell
        case .copyAddress, .hide, .stake, .marketsDetails: return nil
        }
    }

    private func longTapAction(for buttonType: TokenActionType) -> (() -> Void)? {
        switch buttonType {
        case .receive:
            return weakify(self, forFunction: SingleTokenBaseViewModel.copyDefaultAddress)
        case .buy, .send, .exchange, .sell, .copyAddress, .hide, .stake, .marketsDetails:
            return nil
        }
    }

    private func sendIsDisabled() -> Bool {
        guard userWalletModel.config.hasFeature(.send) else {
            return true
        }

        switch walletModel.sendingRestrictions {
        case .zeroWalletBalance, .cantSignLongTransactions, .hasPendingTransaction, .blockchainUnreachable:
            return true
        case .none, .zeroFeeCurrencyBalance:
            return false
        }
    }

    private func isSwapDisabled() -> Bool {
        if walletModel.isCustom {
            return true
        }

        switch walletModel.sendingRestrictions {
        case .cantSignLongTransactions, .blockchainUnreachable:
            return true
        default:
            break
        }

        return !swapAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem)
    }

    private func isReceiveDisabled() -> Bool {
        guard let assetRequirementsManager = walletModel.assetRequirementsManager else {
            return false
        }

        return assetRequirementsManager.hasRequirements(for: amountType)
    }
}

// MARK: - Navigation

extension SingleTokenBaseViewModel {
    func openReceive() {
        let requirementsCondition = walletModel.assetRequirementsManager?.requirementsCondition(for: amountType)
        if let receiveUnavailableAlert = SingleTokenAlertBuilder().receiveAlert(for: requirementsCondition) {
            alert = receiveUnavailableAlert
            return
        }

        tokenRouter.openReceive(walletModel: walletModel)
    }

    func openBuyCryptoIfPossible() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if !exchangeUtility.buyAvailable {
            alert = SingleTokenAlertBuilder().buyUnavailableAlert(for: walletModel.tokenItem)
            return
        }

        tokenRouter.openBuyCryptoIfPossible(walletModel: walletModel)
    }

    func openSend() {
        if let sendUnavailableAlert = SingleTokenAlertBuilder().sendAlert(for: walletModel.sendingRestrictions) {
            alert = sendUnavailableAlert
            return
        }

        tokenRouter.openSend(walletModel: walletModel)
    }

    func openExchangeAndLogAnalytics() {
        Analytics.log(event: .buttonExchange, params: [.token: walletModel.tokenItem.currencySymbol])
        openExchange()
    }

    func openExchange() {
        let alertBuilder = SingleTokenAlertBuilder()

        switch walletModel.sendingRestrictions {
        case .cantSignLongTransactions, .blockchainUnreachable:
            alert = alertBuilder.sendAlert(for: walletModel.sendingRestrictions)
            return
        default:
            break
        }

        if let alertToDisplay = alertBuilder.swapAlert(
            for: walletModel.tokenItem,
            tokenItemSwapState: swapAvailabilityProvider.swapState(for: walletModel.tokenItem),
            isCustom: walletModel.isCustom
        ) {
            alert = alertToDisplay
            return
        }

        tokenRouter.openExchange(walletModel: walletModel)
    }

    func openStaking() {
        tokenRouter.openStaking(walletModel: walletModel)
    }

    func openSell() {
        if let disabledLocalizedReason = userWalletModel.config.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        let alertBuilder = SingleTokenAlertBuilder()
        if let sendAlert = alertBuilder.sellAlert(
            for: walletModel.tokenItem,
            sellAvailable: exchangeUtility.sellAvailable,
            sendingRestrictions: walletModel.sendingRestrictions
        ) {
            alert = sendAlert
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

    private func openAddressExplorer(at index: Int) {
        guard let url = walletModel.exploreURL(for: index, token: amountType.token) else {
            return
        }

        openExplorer(at: url)
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension SingleTokenBaseViewModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "WalletModel": walletModel.description,
            ]
        )
    }
}
