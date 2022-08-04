//
//  WalletModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 09.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class WalletModel: ObservableObject, Identifiable, Initializable {
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var state: State = .created
    @Published var balanceViewModel: BalanceViewModel!
    @Published var tokenItemViewModels: [TokenItemViewModel] = []
    @Published var tokenViewModels: [TokenBalanceViewModel] = []
    @Published var rates: [String: Decimal] = [:]
    @Published var displayState: DisplayState = .busy

    var wallet: Wallet { walletManager.wallet }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    var hasBalance: Bool {
        if !state.isSuccesfullyLoaded {
            return false
        }

        if wallet.hasPendingTx {
            return true
        }

        if !wallet.isEmpty {
            return true
        }

        return false
    }

    var canCreateOrPurgeWallet: Bool {
        if !wallet.isEmpty || wallet.hasPendingTx {
            return false
        }

        return state.canCreateOrPurgeWallet
    }

    var fiatValue: Decimal {
        getFiat(for: wallet.amounts[.coin]) ?? 0
    }

    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }

    var pendingTransactions: [PendingTransaction] {
        incomingPendingTransactions + outgoingPendingTransactions
    }

    var incomingPendingTransactions: [PendingTransaction] {
        wallet.pendingIncomingTransactions.map {
            PendingTransaction(amountType: $0.amount.type,
                               destination: $0.sourceAddress,
                               transferAmount: $0.amount.string(with: 8),
                               canBePushed: false,
                               direction: .incoming)
        }
    }

    var outgoingPendingTransactions: [PendingTransaction] {
        // let txPusher = walletManager as? TransactionPusher

        return wallet.pendingOutgoingTransactions.map {
            // let isTxStuckByTime = Date().timeIntervalSince($0.date ?? Date()) > Constants.bitcoinTxStuckTimeSec

            return PendingTransaction(amountType: $0.amount.type,
                                      destination: $0.destinationAddress,
                                      transferAmount: $0.amount.string(with: 8),
                                      canBePushed: false, // (txPusher?.isPushAvailable(for: $0.hash ?? "") ?? false) && isTxStuckByTime, //TODO: Enable push
                                      direction: .outgoing)
        }
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        wallet.isEmpty && incomingPendingTransactions.count == 0
    }

    var blockchainNetwork: BlockchainNetwork {
        if wallet.publicKey.derivationPath == nil { // cards without hd wallet
            return .init(wallet.blockchain, derivationPath: wallet.blockchain.derivationPath(for: .legacy))
        }

        return .init(wallet.blockchain, derivationPath: wallet.publicKey.derivationPath)
    }

    let walletManager: WalletManager
    private var bag = Set<AnyCancellable>()
    private var updateTimer: AnyCancellable? = nil
    private let demoBalance: Decimal?
    private let derivationStyle: DerivationStyle
    private var isDemo: Bool { demoBalance != nil }
    private var latestUpdateTime: Date? = nil
    private var updatePublisher: PassthroughSubject<Never, Never>?

    deinit {
        print("🗑 WalletModel deinit")
    }

    init(walletManager: WalletManager, derivationStyle: DerivationStyle, demoBalance: Decimal? = nil) {
        self.walletManager = walletManager
        self.demoBalance = demoBalance
        self.derivationStyle = derivationStyle

        updateBalanceViewModel(with: walletManager.wallet)
        self.walletManager.walletPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] wallet in
                print("💳 Wallet model received update")
                self?.updateBalanceViewModel(with: wallet)
                //                if wallet.hasPendingTx {
                //                    if self.updateTimer == nil {
                //                        self.startUpdatingTimer()
                //                    }
                //                } else {
                //                    self.updateTimer = nil
                //                }
            })
            .store(in: &bag)
    }

    func initialize() {
        AppSettings.shared
            .$selectedCurrencyCode
            .dropFirst()
            .sink { [unowned self] currencyCode in
                self.loadRates(currencyCode: currencyCode)
            }
            .store(in: &bag)
    }

    @discardableResult
    func update(silent: Bool = false) -> AnyPublisher<Never, Never> {
        if let updatePublisher = updatePublisher {
            return updatePublisher.eraseToAnyPublisher()
        }

        // Keep this before the async call
        let newUpdatePublisher = PassthroughSubject<Never, Never>()
        self.updatePublisher = newUpdatePublisher

        DispatchQueue.main.async {
            if let latestUpdateTime = self.latestUpdateTime,
               latestUpdateTime.distance(to: Date()) <= 10 {
                if !silent {
                    self.state = .idle
                }
                self.updatePublisher?.send(completion: .finished)
                self.updatePublisher = nil
                return
            }

            if case .loading = self.state {
                return
            }

            if !silent {
                self.updateBalanceViewModel(with: self.wallet)
                self.state = .loading
                self.displayState = .busy
            }

            print("🔄 Updating wallet model for \(self.wallet.blockchain)")
            self.walletManager.update { result in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    print("🔄 Finished updating wallet model for \(self.wallet.blockchain)")

                    if case let .failure(error) = result {
                        if case let .noAccount(noAccountMessage) = (error as? WalletError) {
                            self.state = .noAccount(message: noAccountMessage)
                            self.loadRates(currencyCode: AppSettings.shared.selectedCurrencyCode)
                        } else {
                            self.state = .failed(error: error.detailedError)
                            self.displayState = .readyForDisplay
                            Analytics.log(error: error)
                        }
                    } else {
                        self.latestUpdateTime = Date()

                        if let demoBalance = self.demoBalance {
                            self.walletManager.wallet.add(coinValue: demoBalance)
                        }

                        if !silent {
                            self.state = .idle
                        }

                        self.loadRates(currencyCode: AppSettings.shared.selectedCurrencyCode)
                    }

                    self.updateBalanceViewModel(with: self.wallet)
                    self.updatePublisher?.send(completion: .finished)
                    self.updatePublisher = nil
                }
            }
        }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    func currencyId(for amount: Amount.AmountType) -> String? {
        switch amount {
        case .coin, .reserve:
            return walletManager.wallet.blockchain.currencyId
        case .token(let token):
            return token.id
        }
    }

    func getRate(for amountType: Amount.AmountType) -> Decimal {
        if let currencyId = self.currencyId(for: amountType),
           let rate = rates[currencyId] {
            return rate
        }

        return 0
    }

    func getRateFormatted(for amountType: Amount.AmountType) -> String {
        var rateString = ""

        if let currencyId = self.currencyId(for: amountType),
           let rate = rates[currencyId] {
            rateString = rate.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
        }

        return rateString
    }


    func getQRReceiveMessage(for amountType: Amount.AmountType? = nil)  -> String {
        let type: Amount.AmountType = amountType ?? wallet.amounts.keys.first(where: { $0.isToken }) ?? .coin
        // todo: handle default token
        let symbol = wallet.amounts[type]?.currencySymbol ?? wallet.blockchain.currencySymbol

        if case let .token(token) = amountType {
            return String(format: "address_qr_code_message_token_format".localized,
                          token.name,
                          symbol,
                          wallet.blockchain.displayName)
        } else {
            return String(format: "address_qr_code_message_format".localized,
                          wallet.blockchain.displayName,
                          symbol)
        }
    }

    func getFiatFormatted(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> String? {
        return getFiat(for: amount, roundingMode: roundingMode)?.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    func getFiat(for amount: Amount?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let amount = amount {
            return getFiat(for: amount.value, currencyId: currencyId(for: amount.type), roundingMode: roundingMode)
        }
        return nil
    }

    func getFiat(for value: Decimal, currencyId: String?, roundingMode: NSDecimalNumber.RoundingMode = .down) -> Decimal? {
        if let currencyId = currencyId,
           let rate = rates[currencyId]
        {
            let fiatValue = value * rate
            if fiatValue == 0 {
                return 0
            }
            return max(fiatValue, 0.01).rounded(scale: 2, roundingMode: roundingMode)
        }
        return nil
    }

    func getCrypto(for amount: Amount?) -> Decimal? {
        guard
            let amount = amount,
            let currencyId = self.currencyId(for: amount.type)
        else {
            return nil
        }

        if let rate = rates[currencyId] {
            return (amount.value / rate).rounded(scale: amount.decimals)
        }
        return nil
    }

    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }

    func exploreURL(for index: Int) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: wallet.addresses[index].value)
    }

    func addTokens(_ tokens: [Token]) {
        latestUpdateTime = nil

        tokens.forEach {
            if walletManager.cardTokens.contains($0) {
                walletManager.removeToken($0)
            }
        }

        walletManager.addTokens(tokens)
        updateTokensViewModels()
    }

    func canRemove(amountType: Amount.AmountType) -> Bool {
        if amountType == .coin && !walletManager.cardTokens.isEmpty {
            return false
        }

        return true
    }

    func removeToken(_ token: Token, for cardId: String) -> Bool {
        guard canRemove(amountType: .token(value: token)) else {
            assertionFailure("Delete token isn't possible")
            return false
        }

        walletManager.removeToken(token)
        tokenItemsRepository.remove(token, blockchainNetwork: blockchainNetwork, for: cardId)
        updateTokensViewModels()
        return true
    }

    func getBalance(for type: Amount.AmountType) -> String {
        return wallet.amounts[type].map { $0.string(with: 8) } ?? ""
    }

    func getFiatBalance(for type: Amount.AmountType) -> String {
        return getFiatFormatted(for: wallet.amounts[type]) ?? Decimal(0).currencyFormatted(code: AppSettings.shared.selectedCurrencyCode)
    }

    func startUpdatingTimer() {
        latestUpdateTime = nil
        print("⏰ Starting updating timer for Wallet model")
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() { [weak self] _ in
                print("⏰ Updating timer alarm ‼️ Wallet model will be updated")
                self?.update()
                self?.updateTimer?.cancel()
            }
    }

    func send(_ tx: Transaction, signer: TangemSigner) -> AnyPublisher<Void, Error> {
        if isDemo {
            return signer.sign(hash: Data.randomData(count: 32),
                               walletPublicKey: wallet.publicKey)
                .map { _ in () }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.startUpdatingTimer()
            })
            .eraseToAnyPublisher()
    }

    func isCustom(_ amountType: Amount.AmountType) -> Bool {
        if state.isLoading {
            return false
        }

        let defaultDerivation = wallet.blockchain.derivationPath(for: derivationStyle)
        let currentDerivation = blockchainNetwork.derivationPath

        if currentDerivation != defaultDerivation {
            return true
        }

        switch amountType {
        case .coin, .reserve:
            return false
        case .token(let token):
            return token.id == nil
        }
    }

    private func updateBalanceViewModel(with wallet: Wallet) {
        balanceViewModel = BalanceViewModel(isToken: false,
                                            hasTransactionInProgress: wallet.hasPendingTx,
                                            state: self.state,
                                            name:  wallet.blockchain.displayName,
                                            fiatBalance: getFiatBalance(for: .coin),
                                            balance: getBalance(for: .coin),
                                            secondaryBalance: "",
                                            secondaryFiatBalance: "",
                                            secondaryName: "")
        updateTokensViewModels()
        updateTokenItemViewModels()
    }

    private func loadRates(currencyCode: String) {
        let currenciesToExchange = [walletManager.wallet.blockchain.currencyId] + walletManager.cardTokens.compactMap { $0.id }

        loadRates(for: Array(currenciesToExchange), currencyCode: currencyCode)
    }

    private func loadRates(for currenciesToExchange: [String], currencyCode: String) {
        tangemApiService
            .loadRates(for: currenciesToExchange, currencyCode: currencyCode)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else {
                    return
                }
                switch completion {
                case .failure(let error):
                    Analytics.log(error: error)
                    self.displayState = .readyForDisplay
                    self.updateBalanceViewModel(with: self.wallet)
                    print(error.localizedDescription)
                case .finished:
                    break
                }
            }) { [weak self] rates in
                guard let self = self else { return }

                if !self.rates.isEmpty && rates.count == 0 {
                    return
                }
                self.displayState = .readyForDisplay
                self.rates = rates
                self.updateBalanceViewModel(with: self.wallet)

            }
            .store(in: &bag)
    }

    private func updateTokensViewModels() {
        tokenViewModels = walletManager.cardTokens.map {
            let type = Amount.AmountType.token(value: $0)
            return TokenBalanceViewModel(token: $0, balance: getBalance(for: type), fiatBalance: getFiatBalance(for: type))
        }
    }

    private func updateTokenItemViewModels() {
        let blockchainAmountType = Amount.AmountType.coin
        let blockchainItem = TokenItemViewModel(from: balanceViewModel,
                                                rate: getRateFormatted(for: blockchainAmountType),
                                                fiatValue: getFiat(for: wallet.amounts[blockchainAmountType]) ?? 0,
                                                blockchainNetwork: blockchainNetwork,
                                                hasTransactionInProgress: wallet.hasPendingTx(for: blockchainAmountType),
                                                isCustom: isCustom(blockchainAmountType),
                                                displayState: self.displayState)

        let items: [TokenItemViewModel] = tokenViewModels.map {
            let amountType = Amount.AmountType.token(value: $0.token)
            return TokenItemViewModel(from: balanceViewModel,
                                      tokenBalanceViewModel: $0,
                                      rate: getRateFormatted(for: amountType),
                                      fiatValue:  getFiat(for: wallet.amounts[amountType]) ?? 0,
                                      blockchainNetwork: blockchainNetwork,
                                      hasTransactionInProgress: wallet.hasPendingTx(for: amountType),
                                      isCustom: isCustom(amountType),
                                      displayState: self.displayState)
        }

        tokenItemViewModels = [blockchainItem] + items
    }
}

extension WalletModel {
    enum State {
        case created
        case idle
        case loading
        case noAccount(message: String)
        case failed(error: Error)

        var isLoading: Bool {
            switch self {
            case .loading, .created:
                return true
            default:
                return false
            }
        }

        var isSuccesfullyLoaded: Bool {
            switch self {
            case .idle, .noAccount:
                return true
            default:
                return false
            }
        }

        var isBlockchainUnreachable: Bool {
            switch self {
            case .failed:
                return true
            default:
                return false
            }
        }

        var isNoAccount: Bool {
            switch self {
            case .noAccount:
                return true
            default:
                return false
            }
        }

        var errorDescription: String? {
            switch self {
            case .failed(let error):
                return error.localizedDescription
            case .noAccount(let message):
                return message
            default:
                return nil
            }
        }

        var failureDescription: String? {
            switch self {
            case .failed(let error):
                return error.localizedDescription
            default:
                return nil
            }
        }

        fileprivate var canCreateOrPurgeWallet: Bool {
            switch self {
            case .failed, .loading, .created:
                return false
            case .noAccount, .idle:
                return true
            }
        }
    }

    enum DisplayState {
        case readyForDisplay
        case busy
    }
}

extension WalletModel.State: Equatable {
    static func == (lhs: WalletModel.State, rhs: WalletModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.noAccount, noAccount),
             (.created, .created),
             (.idle, .idle),
             (.loading, .loading),
             (.failed, .failed):
            return true
        default:
            return false
        }
    }
}
