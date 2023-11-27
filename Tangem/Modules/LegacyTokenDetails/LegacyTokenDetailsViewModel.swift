//
//  LegacyTokenDetailsViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine
import CombineExt
import TangemSdk
import TangemSwapping

class LegacyTokenDetailsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    @Published var alert: AlertBinder? = nil
    @Published var showTradeSheet: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var exchangeButtonIsLoading: Bool = false
    @Published var canSwap: Bool = false

    @Published var exchangeButtonState: ExchangeButtonState = .single(option: .buy)
    @Published var exchangeActionSheet: ActionSheetBinder?

    let card: CardViewModel

    var wallet: Wallet? {
        return walletModel?.wallet
    }

    var balanceAddressViewModel: BalanceAddressViewModel? {
        guard let walletModel else { return nil }

        return .init(
            state: walletModel.state,
            wallet: walletModel.wallet,
            tokenItem: walletModel.tokenItem,
            hasTransactionInProgress: walletModel.hasPendingTransactions,
            name: walletModel.name,
            fiatBalance: walletModel.fiatBalance,
            balance: walletModel.balance,
            isTestnet: walletModel.isTestnet,
            isDemo: walletModel.isDemo
        )
    }

    var walletModel: WalletModel?

    var incomingTransactions: [LegacyTransactionRecord] {
        let transactions = walletModel?.incomingPendingTransactions.filter { $0.amount.type == amountType } ?? []
        return legacyTransactionMapper.mapToIncomingRecords(transactions)
    }

    var outgoingTransactions: [LegacyTransactionRecord] {
        let transactions = walletModel?.outgoingPendingTransactions.filter { $0.amount.type == amountType } ?? []
        return legacyTransactionMapper.mapToOutgoingRecords(transactions)
    }

    var canBuyCrypto: Bool {
        card.canExchangeCrypto && buyCryptoUrl != nil
    }

    var canSellCrypto: Bool {
        card.canExchangeCrypto && sellCryptoUrl != nil
    }

    var buyCryptoUrl: URL? {
        if let wallet = wallet {
            if blockchainNetwork.blockchain.isTestnet {
                return wallet.getTestnetFaucetURL()
            }

            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getBuyUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getBuyUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }
        return nil
    }

    var buyCryptoCloseUrl: String {
        exchangeService.successCloseUrl.removeLatestSlash()
    }

    var sellCryptoRequestUrl: String {
        exchangeService.sellRequestUrl.removeLatestSlash()
    }

    var sellCryptoUrl: URL? {
        if let wallet = wallet {
            let address = wallet.address
            switch amountType {
            case .coin:
                return exchangeService.getSellUrl(currencySymbol: blockchainNetwork.blockchain.currencySymbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .token(let token):
                return exchangeService.getSellUrl(currencySymbol: token.symbol, amountType: amountType, blockchain: blockchainNetwork.blockchain, walletAddress: address)
            case .reserve:
                break
            }
        }

        return nil
    }

    var canSend: Bool {
        guard card.config.hasFeature(.send) else {
            return false
        }

        return walletModel?.canSendTransaction ?? false
    }

    var sendBlockedReason: String? {
        guard let reason = walletModel?.sendBlockedReason else {
            return nil
        }

        if case .cantSignLongTransactions = reason {
            return nil
        }

        return reason.description
    }

    var existentialDepositWarning: String? {
        walletModel?.existentialDepositWarning
    }

    var transactionLengthWarning: String? {
        if canSignLongTransactions {
            return nil
        }

        return Localization.warningLongTransactionMessage
    }

    var title: String {
        if let token = amountType.token {
            return token.name
        } else {
            return wallet?.blockchain.displayName ?? ""
        }
    }

    var tokenSubtitle: String? {
        if amountType.token == nil {
            return nil
        }

        return Localization.walletCurrencySubtitle(blockchainNetwork.blockchain.displayName)
    }

    @Published var rentWarning: String? = nil
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork

    private var bag = Set<AnyCancellable>()
    private var rentWarningSubscription: AnyCancellable?
    private var refreshCancellable: AnyCancellable?

    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()
    private unowned let coordinator: LegacyTokenDetailsRoutable
    private var legacyTransactionMapper: LegacyTransactionMapper {
        LegacyTransactionMapper(formatter: BalanceFormatter())
    }

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    private var canSignLongTransactions: Bool {
        AppUtils().canSignLongTransactions(network: blockchainNetwork)
    }

    private var isCustomToken: Bool {
        amountType.token?.isCustom == true
    }

    init(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType, coordinator: LegacyTokenDetailsRoutable) {
        card = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
        self.coordinator = coordinator

        walletModel = card.walletModelsManager.walletModels.first(where: { $0.amountType == amountType && $0.blockchainNetwork == blockchainNetwork })

        bind()
        updateSwapAvailability()
    }

    func updateSwapAvailability() {
        guard card.canShowSwapping else {
            canSwap = false
            updateExchangeButtons()
            return
        }

        switch amountType {
        case .coin:
            canSwap = swapAvailabilityProvider.canSwap(tokenItem: .blockchain(blockchainNetwork.blockchain))
        case .token(let token):
            canSwap = swapAvailabilityProvider.canSwap(tokenItem: .token(token, blockchainNetwork.blockchain))
        default:
            canSwap = false
        }
        updateExchangeButtons()
    }

    func updateExchangeButtons() {
        exchangeButtonState = .init(
            options: ExchangeButtonType.build(
                canBuyCrypto: canBuyCrypto,
                canSellCrypto: canSellCrypto,
                canSwap: canSwap
            )
        )
    }

    func openExchangeActionSheet() {
        var buttons: [ActionSheet.Button] = exchangeButtonState.options.map { action in
            .default(Text(action.title)) { [weak self] in
                self?.didTapExchangeButtonAction(type: action)
            }
        }

        buttons.append(.cancel())

        let sheet = ActionSheet(title: Text(""), buttons: buttons)
        exchangeActionSheet = ActionSheetBinder(sheet: sheet)
    }

    func didTapExchangeButtonAction(type: ExchangeButtonType) {
        switch type {
        case .buy:
            openBuyCryptoIfPossible()
        case .sell:
            openSellCrypto()
        case .swap:
            openSwapping()
        }
    }

    func isAvailable(type: ExchangeButtonType) -> Bool {
        switch type {
        case .buy:
            return canBuyCrypto
        case .swap:
            return canSwap
        case .sell:
            return canSellCrypto
        }
    }

    func onAppear() {
        Analytics.log(.detailsScreenOpened)
        rentWarningSubscription = walletModel?
            .walletDidChangePublisher
            .filter { !$0.isLoading }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRentWarning()
            }
    }

    func onRemove() {
        guard let walletModel = walletModel else {
            assertionFailure("walletModel isn't found")
            return
        }

        if card.userTokensManager.canRemove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath) {
            showWarningDeleteAlert()
        } else {
            showUnableToHideAlert()
        }
    }

    func tradeCryptoAction() {
        Analytics.log(.buttonExchange)
        showTradeSheet = true
    }

    func processSellCryptoRequest(_ request: String) {
        if let request = exchangeService.extractSellCryptoRequest(from: request) {
            openSendToSell(with: request)
        }
    }

    private func bind() {
        AppLog.shared.debug("🔗 Token Details view model updates binding")
        card.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        walletModel?.walletDidChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func showExplorerURL(url: URL?) {
        guard let url = url else { return }

        openExplorer(at: url)
    }

    func onRefresh(_ done: @escaping () -> Void) {
        Analytics.log(.refreshed)
        DispatchQueue.main.async {
            self.isRefreshing = true
        }
        refreshCancellable = walletModel?
            .update(silent: true)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                AppLog.shared.debug("♻️ Token wallet model loading state changed")
                withAnimation(.default.delay(0.2)) {
                    self.isRefreshing = false
                    done()
                }
            } receiveValue: { _ in
            }
    }

    private func updateRentWarning() {
        walletModel?
            .updateRentWarning()
            .assign(to: \.rentWarning, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func deleteToken() {
        guard let walletModel = walletModel else {
            assertionFailure("WalletModel didn't found")
            return
        }

        Analytics.log(event: .buttonRemoveToken, params: [Analytics.ParameterKey.token: currencySymbol])

        card.userTokensManager.remove(walletModel.tokenItem, derivationPath: walletModel.blockchainNetwork.derivationPath)
        dismiss()
    }

    private func showUnableToHideAlert() {
        let title = Localization.tokenDetailsUnableHideAlertTitle(currencySymbol)

        let message = Localization.tokenDetailsUnableHideAlertMessage(
            currencySymbol,
            walletModel?.blockchainNetwork.blockchain.displayName ?? ""
        )

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text(Localization.commonOk))
        ))
    }

    private func showWarningDeleteAlert() {
        let title = Localization.tokenDetailsHideAlertTitle(currencySymbol)

        alert = warningAlert(
            title: title,
            message: Localization.tokenDetailsHideAlertMessage,
            primaryButton: .destructive(Text(Localization.tokenDetailsHideAlertHide)) { [weak self] in
                self?.deleteToken()
            }
        )
    }

    private func warningAlert(title: String, message: String, primaryButton: Alert.Button) -> AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: primaryButton,
            secondaryButton: Alert.Button.cancel()
        )

        return AlertBinder(alert: alert)
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}

// MARK: - Navigation

extension LegacyTokenDetailsViewModel {
    func openSend() {
        guard let amountToSend = wallet?.amounts[amountType] else { return }

        Analytics.log(.buttonSend)
        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: card)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        let amount = Amount(with: blockchainNetwork.blockchain, type: amountType, value: request.amount)
        coordinator.openSendToSell(
            amountToSend: amount,
            destination: request.targetAddress,
            blockchainNetwork: blockchainNetwork,
            cardViewModel: card
        )
    }

    func openSellCrypto() {
        Analytics.log(.buttonSell)

        if let disabledLocalizedReason = card.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let url = sellCryptoUrl {
            coordinator.openSellCrypto(at: url, sellRequestUrl: sellCryptoRequestUrl) { [weak self] response in
                self?.processSellCryptoRequest(response)
            }
        }
    }

    func openBuyCrypto() {
        if let disabledLocalizedReason = card.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let walletModel = walletModel,
           let token = amountType.token,
           blockchainNetwork.blockchain == .ethereum(testnet: true) {
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletModel: walletModel, signer: card.signer))
            return
        }

        if let url = buyCryptoUrl {
            coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                guard let self else { return }

                Analytics.log(event: .tokenBought, params: [.token: currencySymbol])

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.walletModel?.update(silent: true)
                }
            }
        }
    }

    func openBuyCryptoIfPossible() {
        Analytics.log(.buttonBuy)
        if tangemApiService.geoIpRegionCode == LanguageCode.ru {
            coordinator.openBankWarning {
                self.openBuyCrypto()
            } declineCallback: {
                self.coordinator.openP2PTutorial()
            }
        } else {
            openBuyCrypto()
        }
    }

    func openPushTx(for index: Int) {
        let outgoingPendingTransactions = wallet?.pendingTransactions.filter { !$0.isIncoming }
        guard let tx = outgoingPendingTransactions?[index] else { return }

        coordinator.openPushTx(for: tx, blockchainNetwork: blockchainNetwork, card: card)
    }

    func openExplorer(at url: URL) {
        Analytics.log(.buttonExplore)
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainNetwork.blockchain.displayName)
    }

    func openSwapping() {
        Analytics.log(event: .buttonExchange, params: [.token: currencySymbol])

        if let disabledLocalizedReason = card.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard let walletModel = walletModel,
              let source = sourceCurrency,
              let ethereumNetworkProvider = walletModel.ethereumNetworkProvider,
              let ethereumTransactionProcessor = walletModel.ethereumTransactionProcessor
        else {
            return
        }

        var referrer: SwappingReferrerAccount?

        if let account = keysManager.swapReferrerAccount {
            referrer = SwappingReferrerAccount(address: account.address, fee: account.fee)
        }

        let input = CommonSwappingModulesFactory.InputModel(
            userTokensManager: card.userTokensManager,
            walletModel: walletModel,
            signer: card.signer,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionProcessor: ethereumTransactionProcessor,
            logger: AppLog.shared,
            referrer: referrer,
            source: source,
            walletModelTokens: card.userTokensManager.getAllTokens(for: walletModel.blockchainNetwork)
        )

        coordinator.openSwapping(input: input)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}

// MARK: - Swapping preparing

private extension LegacyTokenDetailsViewModel {
    var sourceCurrency: Currency? {
        let blockchain = blockchainNetwork.blockchain
        let mapper = CurrencyMapper()

        switch amountType {
        case .coin, .reserve:
            return mapper.mapToCurrency(blockchain: blockchain)

        case .token(let token):
            return mapper.mapToCurrency(token: token, blockchain: blockchain)
        }
    }
}
