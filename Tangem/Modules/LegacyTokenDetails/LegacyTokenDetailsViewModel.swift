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
import TangemSdk
import TangemSwapping

class LegacyTokenDetailsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.keysManager) private var keysManager: KeysManager

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

    var walletModel: WalletModel?

    var incomingTransactions: [TransactionRecord] {
        walletModel?.incomingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }

    var outgoingTransactions: [TransactionRecord] {
        walletModel?.outgoingPendingTransactions.filter { $0.amountType == amountType } ?? []
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
                return blockchainNetwork.blockchain.testnetFaucetURL
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
        guard card.canSend else {
            return false
        }

        guard canSignLongTransactions else {
            return false
        }

        return wallet?.canSend(amountType: amountType) ?? false
    }

    var sendBlockedReason: String? {
        guard
            let wallet = walletModel?.wallet,
            let currentAmount = wallet.amounts[amountType],
            let token = amountType.token
        else {
            return nil
        }

        if wallet.hasPendingTx, !wallet.hasPendingTx(for: amountType) { // has pending tx for fee
            return Localization.tokenDetailsSendBlockedTxFormat(wallet.amounts[.coin]?.currencySymbol ?? "")
        }

        // no fee
        if !wallet.hasPendingTx, !canSend, !currentAmount.isZero {
            return Localization.tokenDetailsSendBlockedFeeFormat(
                token.name,
                wallet.blockchain.displayName,
                token.name,
                wallet.blockchain.displayName,
                wallet.blockchain.currencySymbol
            )
        }

        return nil
    }

    var existentialDepositWarning: String? {
        guard
            let blockchain = walletModel?.blockchainNetwork.blockchain,
            let existentialDepositProvider = walletModel?.walletManager as? ExistentialDepositProvider
        else {
            return nil
        }

        let blockchainName = blockchain.displayName
        let existentialDepositAmount = existentialDepositProvider.existentialDeposit.string(roundingMode: .plain)

        return Localization.warningExistentialDepositMessage(blockchainName, existentialDepositAmount)
    }

    var transactionLengthWarning: String? {
        if canSignLongTransactions {
            return nil
        }

        return Localization.tokenDetailsTransactionLengthWarning
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

    @Published var solanaRentWarning: String? = nil
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork

    private var bag = Set<AnyCancellable>()
    private var rentWarningSubscription: AnyCancellable?
    private var refreshCancellable: AnyCancellable?

    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()
    private unowned let coordinator: LegacyTokenDetailsRoutable

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    private var canSignLongTransactions: Bool {
        if let blockchain = walletModel?.blockchainNetwork.blockchain,
           NFCUtils.isPoorNfcQualityDevice,
           case .solana = blockchain {
            return false
        } else {
            return true
        }
    }

    private var isCustomToken: Bool {
        amountType.token?.isCustom == true
    }

    init(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType, coordinator: LegacyTokenDetailsRoutable) {
        card = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
        self.coordinator = coordinator

        walletModel = card.walletModels.first(where: { $0.blockchainNetwork == blockchainNetwork })

        bind()
        updateSwapAvailability()
    }

    func updateSwapAvailability() {
        guard card.canShowSwapping else {
            canSwap = false
            updateExchangeButtons()
            return
        }

        // For a coin we can check it locally
        if amountType == .coin {
            canSwap = SwappingAvailableUtils().canSwap(amountType: .coin, blockchain: blockchainNetwork.blockchain)
            updateExchangeButtons()
            return
        }

        exchangeButtonIsLoading = true

        let networkId = blockchainNetwork.blockchain.networkId
        let currencyId = amountType.token?.id ?? blockchainNetwork.blockchain.id

        tangemApiService
            .loadCoins(requestModel: CoinsListRequestModel(networkIds: [networkId], ids: [currencyId]))
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.canSwap = false
                }

                self?.exchangeButtonIsLoading = false
            } receiveValue: { [weak self] models in
                let coin = models.first(where: { $0.id == currencyId })
                let tokenItem = coin?.items.first(where: { $0.id == currencyId })

                switch tokenItem {
                case .none:
                    self?.canSwap = false
                case .token(let token, let blockchain):
                    self?.canSwap = SwappingAvailableUtils().canSwap(amountType: .token(value: token), blockchain: blockchain)
                case .blockchain(let blockchain):
                    self?.canSwap = SwappingAvailableUtils().canSwap(amountType: .coin, blockchain: blockchain)
                }

                self?.updateExchangeButtons()
            }
            .store(in: &bag)
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
            .$state
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

        if walletModel.canRemove(amountType: amountType) {
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

        walletModel?.walletManager.walletPublisher
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
        guard let rentProvider = walletModel?.walletManager as? RentProvider else {
            return
        }

        rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
            .receive(on: RunLoop.main)
            .sink { _ in

            } receiveValue: { [weak self] rentAmount, minimalBalanceForRentExemption in
                guard
                    let self = self,
                    let amount = walletModel?.wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    self?.solanaRentWarning = nil
                    return
                }
                solanaRentWarning = Localization.solanaRentWarning(rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .store(in: &bag)
    }

    private func deleteToken() {
        guard let walletModel = walletModel else {
            assertionFailure("WalletModel didn't found")
            return
        }

        Analytics.log(event: .buttonRemoveToken, params: [Analytics.ParameterKey.token: currencySymbol])

        card.remove(amountType: amountType, blockchainNetwork: walletModel.blockchainNetwork)
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
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
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
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: walletModel.walletManager, signer: card.signer))
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
        guard let tx = wallet?.pendingOutgoingTransactions[index] else { return }

        coordinator.openPushTx(for: tx, blockchainNetwork: blockchainNetwork, card: card)
    }

    func openExplorer(at url: URL) {
        Analytics.log(.buttonExplore)
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainNetwork.blockchain.displayName)
    }

    func openSwapping() {
        if let disabledLocalizedReason = card.getDisabledLocalizedReason(for: .swapping) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        guard FeatureProvider.isAvailable(.exchange),
              let walletModel = walletModel,
              let source = sourceCurrency
        else {
            return
        }

        var referrer: SwappingReferrerAccount?

        if let account = keysManager.swapReferrerAccount {
            referrer = SwappingReferrerAccount(address: account.address, fee: account.fee)
        }

        let input = CommonSwappingModulesFactory.InputModel(
            userWalletModel: card,
            walletModel: walletModel,
            sender: walletModel.walletManager,
            signer: card.signer,
            logger: AppLog.shared,
            referrer: referrer,
            source: source
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
