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

class WalletModel {
    @Injected(\.ratesRepository) private var ratesRepository: RatesRepository

    /// Listen for fiat and balance changes. This publisher will not be called if the is nothing changed. Use `update(silent:)` for waiting for update
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> {
        _walletDidChangePublisher.eraseToAnyPublisher()
    }

    var state: State {
        _state.value
    }

    /// Listen tx history changes
    var transactionHistoryPublisher: AnyPublisher<TransactionHistoryState, Never> {
        _transactionsHistory.eraseToAnyPublisher()
    }

    var shoudShowFeeSelector: Bool {
        walletManager.allowsFeeSelection
    }

    var tokenItem: TokenItem {
        switch amountType {
        case .coin, .reserve:
            return .blockchain(wallet.blockchain)
        case .token(let token):
            return .token(token, wallet.blockchain)
        }
    }

    var name: String {
        switch amountType {
        case .coin, .reserve:
            return wallet.blockchain.displayName
        case .token(let token):
            return token.name
        }
    }

    var isMainToken: Bool {
        switch amountType {
        case .coin, .reserve:
            return true
        case .token:
            return false
        }
    }

    var balanceValue: Decimal {
        wallet.amounts[amountType]?.value ?? .zero
    }

    var balance: String {
        return formatter.formatCryptoBalance(balanceValue, currencyCode: tokenItem.currencySymbol)
    }

    var isZeroAmount: Bool {
        wallet.amounts[amountType]?.isZero ?? true
    }

    var fiatBalance: String {
        formatter.formatFiatBalance(fiatValue)
    }

    var fiatValue: Decimal? {
        guard let currencyId = tokenItem.currencyId else {
            return nil
        }

        return converter.convertToFiat(value: balanceValue, from: currencyId)
    }

    var rateFormatted: String {
        guard let rate else { return "" }

        return formatter.formatFiatBalance(rate, formattingOptions: .defaultFiatFormattingOptions)
    }

    var hasPendingTransactions: Bool {
        wallet.hasPendingTx(for: amountType)
    }

    var wallet: Wallet { walletManager.wallet }

    var addressNames: [String] {
        wallet.addresses.map { $0.localizedName }
    }

    var defaultAddress: String {
        wallet.defaultAddress.value
    }

    var isTestnet: Bool {
        wallet.blockchain.isTestnet
    }

    var incomingPendingTransactions: [LegacyTransactionRecord] {
        wallet.pendingIncomingTransactions.map {
            LegacyTransactionRecord(
                amountType: $0.amount.type,
                destination: $0.sourceAddress,
                timeFormatted: "",
                date: $0.date,
                transferAmount: formatter.formatCryptoBalance(
                    $0.amount.value,
                    currencyCode: $0.amount.currencySymbol
                ),
                transactionType: .receive,
                status: .inProgress
            )
        }
    }

    var outgoingPendingTransactions: [LegacyTransactionRecord] {
        return wallet.pendingOutgoingTransactions.map {
            return LegacyTransactionRecord(
                amountType: $0.amount.type,
                destination: $0.destinationAddress,
                timeFormatted: "",
                date: $0.date,
                transferAmount: formatter.formatCryptoBalance(
                    $0.amount.value,
                    currencyCode: $0.amount.currencySymbol
                ),
                transactionType: .send,
                status: .inProgress
            )
        }
    }

    var transactions: [LegacyTransactionRecord] {
        // TODO: Remove after transaction history implementation in BlockchainSDK
        if FeatureStorage().useFakeTxHistory {
            return Bool.random() ? FakeTransactionHistoryFactory().createFakeTxs(currencyCode: wallet.amounts[.coin]?.currencySymbol ?? "") : []
        }

        return TransactionHistoryMapper().convertToTransactionRecords(wallet.transactions, for: wallet.addresses)
    }

    var isEmptyIncludingPendingIncomingTxs: Bool {
        wallet.isEmpty && incomingPendingTransactions.isEmpty
    }

    var blockchainNetwork: BlockchainNetwork {
        if wallet.publicKey.derivationPath == nil { // cards without hd wallet
            return BlockchainNetwork(wallet.blockchain, derivationPath: nil)
        }

        return .init(wallet.blockchain, derivationPath: wallet.publicKey.derivationPath)
    }

    var qrReceiveMessage: String {
        // TODO: handle default token
        let symbol = wallet.amounts[amountType]?.currencySymbol ?? wallet.blockchain.currencySymbol

        let currencyName: String
        if case .token(let token) = amountType {
            currencyName = token.name
        } else {
            currencyName = wallet.blockchain.displayName
        }

        return Localization.addressQrCodeMessageFormat(currencyName, symbol, wallet.blockchain.displayName)
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let amountType: Amount.AmountType
    let isCustom: Bool

    private let walletManager: WalletManager
    private var updateTimer: AnyCancellable?
    private var txHistoryUpdateSubscription: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updatePublisher: PassthroughSubject<State, Never>?
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")
    private var _walletDidChangePublisher: CurrentValueSubject<State, Never> = .init(.created)
    private var _state: CurrentValueSubject<State, Never> = .init(.created)
    private var _rate: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private var _transactionsHistory: CurrentValueSubject<TransactionHistoryState, Never> = .init(.notLoaded)

    private var rate: Decimal? {
        guard let currencyId = tokenItem.currencyId else {
            return nil
        }

        return ratesRepository.rates[currencyId]
    }

    private let converter = BalanceConverter()
    private let formatter = BalanceFormatter()

    deinit {
        AppLog.shared.debug("🗑 \(self) deinit")
    }

    init(
        walletManager: WalletManager,
        amountType: Amount.AmountType,
        isCustom: Bool
    ) {
        self.walletManager = walletManager
        self.amountType = amountType
        self.isCustom = isCustom

        bind()
    }

    func bind() {
        AppSettings.shared
            .$selectedCurrencyCode
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .dropFirst()
            .receive(on: updateQueue)
            .receiveValue { [weak self] _ in
                self?.loadRates()
            }
            .store(in: &bag)

        walletManager.statePublisher
            .filter { !$0.isInitialState }
            .combineLatest(walletManager.walletPublisher) // listen pending tx
            .receive(on: updateQueue)
            .sink { [weak self] newState, _ in
                self?.walletManagerDidUpdate(newState)
            }
            .store(in: &bag)

        ratesRepository
            .ratesPublisher
            .compactMap { [tokenItem] rates -> Decimal? in
                guard let currencyId = tokenItem.currencyId else { return nil }

                return rates[currencyId]
            }
            .removeDuplicates()
            .sink { [weak self] rate in
                guard let self else { return }

                AppLog.shared.debug("🔄 Rate updated for \(self)")
                _rate.send(rate)
            }
            .store(in: &bag)

        _state
            .removeDuplicates()
            .combineLatest(_rate.removeDuplicates())
            .map { $0.0 }
            .weakAssign(to: \._walletDidChangePublisher.value, on: self)
            .store(in: &bag)
    }

    // MARK: - Update wallet model

    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        update(silent: silent)
            .combineLatest(updateTransactionsHistory())
            .mapVoid()
            .eraseToAnyPublisher()
    }

    @discardableResult
    /// Do not use with flatMap.
    func update(silent: Bool) -> AnyPublisher<State, Never> {
        // If updating already in process return updating Publisher
        if let updatePublisher = updatePublisher {
            return updatePublisher.eraseToAnyPublisher()
        }

        // Keep this before the async call
        let newUpdatePublisher = PassthroughSubject<State, Never>()
        updatePublisher = newUpdatePublisher

        if case .loading = state {
            return newUpdatePublisher.eraseToAnyPublisher()
        }

        AppLog.shared.debug("🔄 Start updating \(self)")

        if !silent {
            updateState(.loading)
        }

        updateWalletModelSubscription = walletManager
            .updatePublisher()
            .combineLatest(loadRates())
            .receive(on: updateQueue)
            .sink { [weak self] newState, _ in
                guard let self else { return }

                AppLog.shared.debug("🔄 Finished common update for \(self)")

                updatePublisher?.send(mapState(newState))
                updatePublisher?.send(completion: .finished)
                updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    private func walletManagerDidUpdate(_ walletManagerState: WalletManagerState) {
        switch walletManagerState {
        case .loaded:
            AppLog.shared.debug("🔄 Finished updating for \(self)")

            if let demoBalance {
                walletManager.wallet.add(coinValue: demoBalance)
            }
        case .failed:
            AppLog.shared.debug("🔄 Failed updating for \(self)")
        case .loading, .initial:
            break
        }

        updateState(mapState(walletManagerState))
    }

    private func mapState(_ walletManagerState: WalletManagerState) -> WalletModel.State {
        switch walletManagerState {
        case .loaded:
            return .idle
        case .failed(let error):
            switch error as? WalletError {
            case .noAccount(let message):
                return .noAccount(message: message)
            default:
                return .failed(error: error.detailedError.localizedDescription)
            }
        case .loading:
            return .loading
        case .initial:
            return .created
        }
    }

    private func updateState(_ state: State) {
        AppLog.shared.debug("🔄 Updating state for \(self). New state is \(state)")
        DispatchQueue.main.async { [weak self] in // captured as weak at call stack
            self?._state.value = state
        }
    }

    // MARK: - Load Rates

    @discardableResult
    private func loadRates() -> AnyPublisher<[String: Decimal], Never> {
        guard let currencyId = tokenItem.currencyId else {
            return .just(output: [:])
        }

        AppLog.shared.debug("🔄 Start loading rates for \(self)")

        return ratesRepository
            .loadRates(coinIds: [currencyId])
            .handleEvents(receiveOutput: { [weak self] _ in
                AppLog.shared.debug("🔄 Finished loading rates for \(String(describing: self))")
            })
            .eraseToAnyPublisher()
    }

    func startUpdatingTimer() {
        walletManager.setNeedsUpdate()
        AppLog.shared.debug("⏰ Starting updating timer for \(self)")
        updateTimer = Timer.TimerPublisher(
            interval: 10.0,
            tolerance: 0.1,
            runLoop: .main,
            mode: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            AppLog.shared.debug("⏰ Updating timer alarm ‼️ \(String(describing: self)) will be updated")
            self?.update(silent: false)
            self?.updateTimer?.cancel()
        }
    }

    func send(_ tx: Transaction, signer: TangemSigner) -> AnyPublisher<Void, Error> {
        if isDemo {
            return signer.sign(
                hash: Data.randomData(count: 32),
                walletPublicKey: wallet.publicKey
            )
            .mapVoid()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        }

        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.startUpdatingTimer()
            })
            .receive(on: DispatchQueue.main)
            .mapVoid()
            .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        if isDemo {
            let demoFees = DemoUtil().getDemoFee(for: walletManager.wallet.blockchain)
            return .justWithError(output: demoFees)
        }

        return walletManager.getFee(amount: amount, destination: destination)
    }

    func createTransaction(amountToSend: Amount, fee: Fee, destinationAddress: String) throws -> Transaction {
        try walletManager.createTransaction(amount: amountToSend, fee: fee, destinationAddress: destinationAddress)
    }
}

// MARK: - Helpers

extension WalletModel {
    func displayAddress(for index: Int) -> String {
        wallet.addresses[index].value
    }

    func shareAddressString(for index: Int) -> String {
        wallet.getShareString(for: wallet.addresses[index].value)
    }

    func exploreURL(for index: Int, token: Token? = nil) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: wallet.addresses[index].value, token: token)
    }

    func getDecimalBalance(for type: Amount.AmountType) -> Decimal? {
        return wallet.amounts[type]?.value
    }
}

// MARK: Transaction history

extension WalletModel {
    func updateTransactionsHistory() -> AnyPublisher<TransactionHistoryState, Never> {
        // TODO: Remove after transaction history implementation in BlockchainSDK
        if FeatureStorage().useFakeTxHistory {
            return loadFakeTransactionHistory()
                .replaceError(with: ())
                .map { self._transactionsHistory.value }
                .eraseToAnyPublisher()
        }

        return .just(output: .notSupported)
    }

    // MARK: - Fake tx history related

    private func loadFakeTransactionHistory() -> AnyPublisher<Void, Error> {
        // TODO: Remove after transaction history implementation in BlockchainSDK
        guard FeatureStorage().useFakeTxHistory else {
            return .anyFail(error: "Can't use fake history")
        }

        switch _transactionsHistory.value {
        case .notLoaded, .notSupported:
            _transactionsHistory.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._transactionsHistory.value = .failedToLoad("Failed to load tx history")
                    return ()
                }
                .eraseError()
                .eraseToAnyPublisher()
        case .failedToLoad:
            _transactionsHistory.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._transactionsHistory.value = .loaded
                    return ()
                }
                .eraseError()
                .eraseToAnyPublisher()
        case .loaded:
            _transactionsHistory.value = .loading
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._transactionsHistory.value = .notSupported
                    return ()
                }
                .eraseError()
                .eraseToAnyPublisher()
        case .loading:
            return Just(())
                .delay(for: 5, scheduler: DispatchQueue.main)
                .map {
                    self._transactionsHistory.value = .loaded
                    return ()
                }
                .eraseError()
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - States

extension WalletModel {
    enum State: Hashable {
        case created
        case idle
        case loading
        case noAccount(message: String)
        case failed(error: String)
        case noDerivation

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
            case .failed(let localizedDescription):
                return localizedDescription
            case .noAccount(let message):
                return message
            default:
                return nil
            }
        }

        var failureDescription: String? {
            switch self {
            case .failed(let localizedDescription):
                return localizedDescription
            default:
                return nil
            }
        }

        fileprivate var canCreateOrPurgeWallet: Bool {
            switch self {
            case .failed, .loading, .created, .noDerivation:
                return false
            case .noAccount, .idle:
                return true
            }
        }
    }

    enum WalletManagerUpdateResult: Hashable {
        case success
        case noAccount(message: String)
    }
}

extension WalletModel: Equatable {
    static func == (lhs: WalletModel, rhs: WalletModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension WalletModel: Identifiable {
    var id: Int {
        Id(blockchainNetwork: blockchainNetwork, amountType: amountType).id
    }
}

extension WalletModel: Hashable {
    func hash(into hasher: inout Hasher) {
        let id = Id(blockchainNetwork: blockchainNetwork, amountType: amountType)
        hasher.combine(id)
    }
}

extension WalletModel {
    enum TransactionHistoryState {
        case notSupported
        case notLoaded
        case loading
        case failedToLoad(Error)
        case loaded
    }
}

extension WalletModel {
    struct Id: Hashable, Identifiable, Equatable {
        var id: Int { hashValue }

        let blockchainNetwork: BlockchainNetwork
        let amountType: Amount.AmountType
    }
}

// MARK: - ExistentialDepositProvider

extension WalletModel {
    var existentialDepositWarning: String? {
        guard let existentialDepositProvider = walletManager as? ExistentialDepositProvider else {
            return nil
        }

        let blockchainName = blockchainNetwork.blockchain.displayName
        let existentialDepositAmount = existentialDepositProvider.existentialDeposit.string(roundingMode: .plain)
        return Localization.warningExistentialDepositMessage(blockchainName, existentialDepositAmount)
    }
}

// MARK: - RentProvider

extension WalletModel {
    func updateRentWarning() -> AnyPublisher<String?, Never> {
        guard let rentProvider = walletManager as? RentProvider else {
            return .just(output: nil)
        }

        return rentProvider.rentAmount()
            .zip(rentProvider.minimalBalanceForRentExemption())
            .receive(on: RunLoop.main)
            .map { [weak self] rentAmount, minimalBalanceForRentExemption in
                guard
                    let self = self,
                    let amount = wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    return nil
                }

                return Localization.solanaRentWarning(rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension WalletModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": name,
                "isMainToken": isMainToken,
                "tokenItem": "\(tokenItem.name) (\(tokenItem.networkName))",
            ]
        )
    }
}

// MARK: - Interfaces

extension WalletModel {
    var blockchainDataProvider: BlockchainDataProvider {
        walletManager
    }

    var transactionCreator: TransactionCreator {
        walletManager
    }

    var transactionSender: TransactionSender {
        walletManager
    }

    var transactionPusher: TransactionPusher? {
        walletManager as? TransactionPusher
    }

    var withdrawalValidator: WithdrawalValidator? {
        walletManager as? WithdrawalValidator
    }

    var ethereumGasLoader: EthereumGasLoader? {
        walletManager as? EthereumGasLoader
    }

    var ethereumTransactionSigner: EthereumTransactionSigner? {
        walletManager as? EthereumTransactionSigner
    }

    var ethereumNetworkProvider: EthereumNetworkProvider? {
        walletManager as? EthereumNetworkProvider
    }

    var ethereumTransactionProcessor: EthereumTransactionProcessor? {
        walletManager as? EthereumTransactionProcessor
    }
}
