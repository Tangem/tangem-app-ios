//
//  TokenDetailsViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//
import SwiftUI
import BlockchainSdk
import Combine
import TangemSdk

class TokenDetailsViewModel: ObservableObject {
    @Injected(\.exchangeService) private var exchangeService: ExchangeService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var alert: AlertBinder? = nil
    @Published var showTradeSheet: Bool = false
    @Published var isRefreshing: Bool = false

    let card: CardViewModel

    var wallet: Wallet? {
        return walletModel?.wallet
    }

    var walletModel: WalletModel?

    var incomingTransactions: [PendingTransaction] {
        walletModel?.incomingPendingTransactions.filter { $0.amountType == amountType } ?? []
    }

    var outgoingTransactions: [PendingTransaction] {
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

        return wallet?.canSend(amountType: self.amountType) ?? false
    }

    var sendBlockedReason: String? {
        guard let wallet = walletModel?.wallet,
              let currentAmount = wallet.amounts[amountType], amountType.isToken else { return nil }

        if wallet.hasPendingTx && !wallet.hasPendingTx(for: amountType) { // has pending tx for fee
            return String(format: "token_details_send_blocked_tx_format".localized, wallet.amounts[.coin]?.currencySymbol ?? "")
        }

        if !wallet.hasPendingTx && !canSend && !currentAmount.isZero { // no fee23423
            return String(format: "token_details_send_blocked_fee_format".localized, wallet.blockchain.displayName, wallet.blockchain.displayName)
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

        return String(format: "warning_existential_deposit_message".localized, blockchainName, existentialDepositAmount)
    }

    var transactionLengthWarning: String? {
        if canSignLongTransactions {
            return nil
        }

        return "token_details_transaction_length_warning".localized
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

        return "wallet_currency_subtitle".localized(blockchainNetwork.blockchain.displayName)
    }

    @Published var solanaRentWarning: String? = nil
    let amountType: Amount.AmountType
    let blockchainNetwork: BlockchainNetwork

    private var bag = Set<AnyCancellable>()
    private var rentWarningSubscription: AnyCancellable?
    private var refreshCancellable: AnyCancellable? = nil
    private lazy var testnetBuyCryptoService: TestnetBuyCryptoService = .init()
    private unowned let coordinator: TokenDetailsRoutable

    private var currencySymbol: String {
        amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
    }

    private var canSignLongTransactions: Bool {
        if let blockchain = walletModel?.blockchainNetwork.blockchain,
           NFCUtils.isPoorNfcQualityDevice,
           case .solana = blockchain
        {
            return false
        } else {
            return true
        }
    }

    init(cardModel: CardViewModel, blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType, coordinator: TokenDetailsRoutable) {
        self.card = cardModel
        self.blockchainNetwork = blockchainNetwork
        self.amountType = amountType
        self.coordinator = coordinator

        walletModel = card.walletModels.first(where: { $0.blockchainNetwork == blockchainNetwork })

        bind()
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

    func sendAnalyticsEvent(_ event: Analytics.Event) {
        switch event {
        case .userBoughtCrypto:
            Analytics.log(event, params: [.currencyCode: blockchainNetwork.blockchain.currencySymbol])
        default:
            break
        }
    }

    private func bind() {
        print("🔗 Token Details view model updates binding")
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

        self.openExplorer(at: url)
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
                print("♻️ Token wallet model loading state changed")
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

            } receiveValue: { [weak self] (rentAmount, minimalBalanceForRentExemption) in
                guard
                    let self = self,
                    let amount = self.walletModel?.wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    self?.solanaRentWarning = nil
                    return
                }
                self.solanaRentWarning = String(format: "solana_rent_warning".localized, rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .store(in: &bag)
    }

    private func deleteToken() {
        guard let walletModel = walletModel else {
            assertionFailure("WalletModel didn't found")
            return
        }

        let currencySymbol = amountType.token?.symbol ?? blockchainNetwork.blockchain.currencySymbol
        Analytics.log(.buttonRemoveToken, params: [Analytics.ParameterKey.token: currencySymbol])

        let item = CommonUserWalletModel.RemoveItem(amount: amountType, blockchainNetwork: walletModel.blockchainNetwork)
        card.userWalletModel?.remove(item: item)
        dismiss()
    }

    private func showUnableToHideAlert() {
        let title = "token_details_unable_hide_alert_title".localized(currencySymbol)

        let message = "token_details_unable_hide_alert_message".localized([
            currencySymbol,
            walletModel?.blockchainNetwork.blockchain.displayName ?? "",
        ])

        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("common_ok"))
        ))
    }

    private func showWarningDeleteAlert() {
        let title = "token_details_hide_alert_title".localized(currencySymbol)

        alert = warningAlert(
            title: title,
            message: "token_details_hide_alert_message".localized,
            primaryButton: .destructive(Text("token_details_hide_alert_hide")) { [weak self] in
                self?.deleteToken()
            }
        )
    }

    private func warningAlert(title: String, message: String, primaryButton: Alert.Button) -> AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message.localized),
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
extension TokenDetailsViewModel {
    func openSend() {
        guard let amountToSend = self.wallet?.amounts[amountType] else { return }

        Analytics.log(.buttonSend)
        coordinator.openSend(amountToSend: amountToSend, blockchainNetwork: blockchainNetwork, cardViewModel: card)
    }

    func openSendToSell(with request: SellCryptoRequest) {
        let amount = Amount(with: blockchainNetwork.blockchain, value: request.amount)
        coordinator.openSendToSell(amountToSend: amount,
                                   destination: request.targetAddress,
                                   blockchainNetwork: blockchainNetwork,
                                   cardViewModel: card)
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
        Analytics.log(.buttonBuy)
        if let disabledLocalizedReason = card.getDisabledLocalizedReason(for: .exchange) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        if let walletModel = self.walletModel,
           let token = amountType.token,
           blockchainNetwork.blockchain == .ethereum(testnet: true) {
            testnetBuyCryptoService.buyCrypto(.erc20Token(token, walletManager: walletModel.walletManager, signer: card.signer))
            return
        }

        if let url = buyCryptoUrl {
            coordinator.openBuyCrypto(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
                self?.sendAnalyticsEvent(.userBoughtCrypto)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.walletModel?.update(silent: true)
                }
            }
        }
    }

    func openBuyCryptoIfPossible() {
        Analytics.log(.buttonBuyCrypto)
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
        guard let tx =  wallet?.pendingOutgoingTransactions[index] else { return }

        coordinator.openPushTx(for: tx, blockchainNetwork: blockchainNetwork, card: card)
    }

    func openExplorer(at url: URL) {
        Analytics.log(.buttonExplore)
        coordinator.openExplorer(at: url, blockchainDisplayName: blockchainNetwork.blockchain.displayName)
    }

    func dismiss() {
        coordinator.dismiss()
    }
}
