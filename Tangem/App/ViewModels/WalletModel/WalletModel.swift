//
//  WalletModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 09.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk

class WalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    var walletModelId: WalletModel.Id {
        .init(blockchainNetwork: blockchainNetwork, amountType: amountType)
    }

    /// Listen for fiat and balance changes. This publisher will not be called if the is nothing changed. Use `update(silent:)` for waiting for update
    var walletDidChangePublisher: AnyPublisher<WalletModel.State, Never> {
        _walletDidChangePublisher.eraseToAnyPublisher()
    }

    var state: State {
        _state.value
    }

    /// Listen tx history changes
    var transactionHistoryPublisher: AnyPublisher<TransactionHistoryState, Never> {
        transactionHistoryState()
    }

    var isSupportedTransactionHistory: Bool {
        _transactionHistoryService != nil
    }

    var shouldShowFeeSelector: Bool {
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

    var feeTokenItem: TokenItem {
        let blockchain = blockchainNetwork.blockchain

        switch blockchain.feePaidCurrency {
        case .coin:
            return .blockchain(blockchain)
        case .token(let value):
            return .token(value, blockchain)
        case .sameCurrency:
            return tokenItem
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

    var balanceValue: Decimal? {
        if state.isNoAccount {
            return 0
        }

        return wallet.amounts[amountType]?.value
    }

    var balance: String {
        guard let balanceValue else { return BalanceFormatter.defaultEmptyBalanceString }

        return formatter.formatCryptoBalance(balanceValue, currencyCode: tokenItem.currencySymbol)
    }

    var isZeroAmount: Bool {
        wallet.amounts[amountType]?.isZero ?? true
    }

    var fiatBalance: String {
        formatter.formatFiatBalance(fiatValue)
    }

    var fiatValue: Decimal? {
        guard let balanceValue,
              let currencyId = tokenItem.currencyId else {
            return nil
        }

        return converter.convertToFiat(value: balanceValue, from: currencyId)
    }

    var rateFormatted: String {
        guard let rate = quote?.price else {
            return BalanceFormatter.defaultEmptyBalanceString
        }

        return formatter.formatFiatBalance(rate, formattingOptions: .defaultFiatFormattingOptions)
    }

    var quote: TokenQuote? {
        quotesRepository.quote(for: tokenItem)
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

    var pendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { !$0.isDummy }
    }

    var incomingPendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { $0.isIncoming }
    }

    var outgoingPendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { !$0.isIncoming }
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

    var sendingRestrictions: TransactionSendAvailabilityProvider.SendingRestrictions? {
        TransactionSendAvailabilityProvider().sendingRestrictions(walletModel: self)
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        swapAvailabilityProvider
            .tokenItemsAvailableToSwapPublisher
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let amountType: Amount.AmountType
    let isCustom: Bool

    private let walletManager: WalletManager
    private let _transactionHistoryService: TransactionHistoryService?
    private var updateTimer: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updatePublisher: PassthroughSubject<State, Never>?
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")
    private var _walletDidChangePublisher: CurrentValueSubject<State, Never> = .init(.created)
    private var _state: CurrentValueSubject<State, Never> = .init(.created)
    private var _rate: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private var _localPendingTransactionSubject: PassthroughSubject<Void, Never> = .init()

    private let converter = BalanceConverter()
    private let formatter = BalanceFormatter()

    deinit {
        AppLog.shared.debug("🗑 \(self) deinit")
    }

    init(
        walletManager: WalletManager,
        transactionHistoryService: TransactionHistoryService?,
        amountType: Amount.AmountType,
        isCustom: Bool
    ) {
        self.walletManager = walletManager
        _transactionHistoryService = transactionHistoryService
        self.amountType = amountType
        self.isCustom = isCustom

        bind()
    }

    func bind() {
        walletManager.statePublisher
            .filter { !$0.isInitialState }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                self?.walletManagerDidUpdate(newState)
            }
            .store(in: &bag)

        quotesRepository
            .quotesPublisher
            .compactMap { [tokenItem] quotes -> Decimal? in
                guard let currencyId = tokenItem.currencyId else { return nil }

                return quotes[currencyId]?.price
            }
            .removeDuplicates()
            .sink { [weak self] rate in
                guard let self else { return }

                AppLog.shared.debug("🔄 Quotes updated for \(self)")
                _rate.send(rate)
            }
            .store(in: &bag)

        _state
            .removeDuplicates()
            .combineLatest(_rate.removeDuplicates(), walletManager.walletPublisher)
            .map { $0.0 }
            .assign(to: \._walletDidChangePublisher.value, on: self, ownership: .weak)
            .store(in: &bag)
    }

    // MARK: - Update wallet model

    func generalUpdate(silent: Bool) -> AnyPublisher<Void, Never> {
        _transactionHistoryService?.clearHistory()

        return Publishers
            .CombineLatest(update(silent: silent), updateTransactionsHistory())
            .mapToVoid()
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
            .combineLatest(loadQuotes())
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

    // MARK: - Load Quotes

    private func loadQuotes() -> AnyPublisher<Void, Never> {
        guard let currencyId = tokenItem.currencyId else {
            return .just(output: ())
        }

        AppLog.shared.debug("🔄 Start loading quotes for \(self)")

        return quotesRepository
            .loadQuotes(currencyIds: [currencyId])
            .handleEvents(receiveOutput: { [weak self] _ in
                AppLog.shared.debug("🔄 Finished loading quotes for \(String(describing: self))")
            })
            .mapToVoid()
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
        .withWeakCaptureOf(self)
        .flatMap { root, _ in
            AppLog.shared.debug("⏰ Updating timer alarm ‼️ \(String(describing: self)) will be updated")
            return root.generalUpdate(silent: false)
        }
        .sink { [weak self] in
            self?.updateTimer?.cancel()
        }
    }

    func send(_ tx: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        if isDemo {
            let hash = Data.randomData(count: 32)
            return signer.sign(hash: hash, walletPublicKey: wallet.publicKey)
                .map { _ in TransactionSendResult(hash: hash.hexString) }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        return walletManager.send(tx, signer: signer)
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Force update transactions history to take a new pending transaction from the local storage
                self?._localPendingTransactionSubject.send(())
                self?.startUpdatingTimer()
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        return walletManager.estimatedFee(amount: amount)
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

    func exploreTransactionURL(for hash: String) -> URL? {
        if isDemo {
            return nil
        }

        return wallet.getExploreURL(for: hash)
    }

    func getDecimalBalance(for type: Amount.AmountType) -> Decimal? {
        return wallet.amounts[type]?.value
    }
}

// MARK: - Transaction history

extension WalletModel {
    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        guard let _transactionHistoryService else {
            AppLog.shared.debug("TransactionsHistory for \(self) not supported")
            return .just(output: ())
        }

        AppLog.shared.debug("TransactionsHistory for \(self) start the updating")
        return _transactionHistoryService.update()
    }

    private func transactionHistoryState() -> AnyPublisher<WalletModel.TransactionHistoryState, Never> {
        guard let _transactionHistoryService else {
            return .just(output: .notSupported)
        }

        return Publishers.Merge(
            _localPendingTransactionSubject.withLatestFrom(_transactionHistoryService.statePublisher),
            _transactionHistoryService.statePublisher
        )
        .map { [weak self] state -> WalletModel.TransactionHistoryState in
            switch state {
            case .initial:
                return .notLoaded
            case .loading:
                return .loading
            case .loaded:
                var items = self?._transactionHistoryService?.items ?? []
                self?.insertPendingTransactionRecordIfNeeded(into: &items)
                return .loaded(items: items)
            case .failedToLoad(let error):
                return .error(error)
            }
        }
        .eraseToAnyPublisher()
    }

    private func insertPendingTransactionRecordIfNeeded(into items: inout [TransactionRecord]) {
        guard !pendingTransactions.isEmpty else {
            AppLog.shared.debug("\(self) has not local pending transactions")
            return
        }

        AppLog.shared.debug("\(self) has pending local transactions \(pendingTransactions.map { $0.hash }). Try to insert it to transaction history")
        let mapper = PendingTransactionRecordMapper(formatter: formatter)

        pendingTransactions.forEach { pending in
            if items.contains(where: { $0.hash == pending.hash }) {
                AppLog.shared.debug("\(self) Transaction history already contains \(pending.hash)")
            } else {
                let record = mapper.mapToTransactionRecord(pending: pending)
                AppLog.shared.debug("\(self) Inserted to transaction history \(record.hash)")
                items.insert(record, at: 0)
            }
        }
    }
}

// MARK: - ExistentialDepositProvider

extension WalletModel {
    var existentialDeposit: Amount? {
        existentialDepositProvider?.existentialDeposit
    }

    var existentialDepositWarning: String? {
        guard let existentialDeposit = existentialDeposit else {
            return nil
        }

        let blockchainName = blockchainNetwork.blockchain.displayName
        let existentialDepositAmount = existentialDeposit.string(roundingMode: .plain)
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
            .receive(on: DispatchQueue.main)
            .map { [weak self] rentAmount, minimalBalanceForRentExemption in
                guard
                    let self = self,
                    let amount = wallet.amounts[.coin],
                    amount < minimalBalanceForRentExemption
                else {
                    return nil
                }

                return Localization.warningSolanaRentFeeMessage(rentAmount.description, minimalBalanceForRentExemption.description)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
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

    var signatureCountValidator: SignatureCountValidator? {
        walletManager as? SignatureCountValidator
    }

    var addressResolver: AddressResolver? {
        walletManager as? AddressResolver
    }

    var hasRent: Bool {
        walletManager is RentProvider
    }

    var existentialDepositProvider: ExistentialDepositProvider? {
        walletManager as? ExistentialDepositProvider
    }
}

extension WalletModel: TransactionHistoryFetcher {
    var canFetchHistory: Bool {
        _transactionHistoryService?.canFetchHistory ?? false
    }

    func clearHistory() {
        _transactionHistoryService?.clearHistory()
    }
}
