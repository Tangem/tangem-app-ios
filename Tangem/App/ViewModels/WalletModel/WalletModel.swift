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
import TangemStaking
import TangemFoundation

class WalletModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    @Injected(\.accountHealthChecker) private var accountHealthChecker: AccountHealthChecker

    private(set) lazy var walletModelId: WalletModel.Id = .init(tokenItem: tokenItem)

    var state: State {
        _state.value
    }

    var statePublisher: AnyPublisher<State, Never> {
        _state.eraseToAnyPublisher()
    }

    var rate: WalletModel.Rate {
        _rate.value
    }

    var ratePublisher: AnyPublisher<WalletModel.Rate, Never> {
        _rate.eraseToAnyPublisher()
    }

    /// Listen tx history changes
    var transactionHistoryPublisher: AnyPublisher<TransactionHistoryState, Never> {
        transactionHistoryState()
    }

    var isSupportedTransactionHistory: Bool {
        _transactionHistoryService != nil
    }

    var stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never> {
        _stakingManager.map { $0.statePublisher } ?? .just(output: .notEnabled)
    }

    var stakingManagerState: StakingManagerState {
        _stakingManager?.state ?? .notEnabled
    }

    var shouldShowFeeSelector: Bool {
        walletManager.allowsFeeSelection
    }

    var tokenItem: TokenItem {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return .blockchain(blockchainNetwork)
        case .token(let token):
            return .token(token, blockchainNetwork)
        }
    }

    var feeTokenItem: TokenItem {
        switch blockchainNetwork.blockchain.feePaidCurrency {
        case .coin:
            return .blockchain(blockchainNetwork)
        case .token(let value):
            return .token(value, blockchainNetwork)
        case .sameCurrency:
            return tokenItem
        case .feeResource(let type):
            // We use this when displaying the fee currency on the 'Send' screen.
            // This is because when sending KOIN, we use MANA as the fee.
            return .token(
                Token(
                    name: type.rawValue,
                    symbol: type.rawValue,
                    contractAddress: "",
                    decimalCount: 0
                ),
                blockchainNetwork
            )
        }
    }

    var name: String {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return wallet.blockchain.displayName
        case .token(let token):
            return token.name
        }
    }

    var isMainToken: Bool {
        switch amountType {
        case .coin, .reserve, .feeResource:
            return true
        case .token:
            return false
        }
    }

    /// Quotes can't be fetched for custom tokens.
    var canUseQuotes: Bool { tokenItem.currencyId != nil }

    var quote: TokenQuote? {
        quotesRepository.quote(for: tokenItem)
    }

    var hasPendingTransactions: Bool {
        wallet.hasPendingTx(for: amountType)
    }

    var wallet: Wallet { walletManager.wallet }

    var addresses: [String] {
        wallet.addresses.map { $0.value }
    }

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
        wallet.pendingTransactions.filter { !$0.isDummy && $0.amount.type == amountType }
    }

    var incomingPendingTransactions: [PendingTransactionRecord] {
        wallet.pendingTransactions.filter { $0.isIncoming && $0.amount.type == amountType }
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
        sendAvailabilityProvider.sendingRestrictions(walletModel: self)
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> {
        Publishers.Merge(
            expressAvailabilityProvider.availabilityDidChangePublisher,
            stakingManagerStatePublisher.mapToVoid()
        )
        .eraseToAnyPublisher()
    }

    var isDemo: Bool { demoBalance != nil }
    var demoBalance: Decimal?

    let amountType: Amount.AmountType
    let isCustom: Bool

    private let sendAvailabilityProvider: TransactionSendAvailabilityProvider
    private let tokenBalancesRepository: TokenBalancesRepository
    private let walletManager: WalletManager
    private let _stakingManager: StakingManager?
    private let _transactionHistoryService: TransactionHistoryService?
    private var updateTimer: AnyCancellable?
    private var updateWalletModelSubscription: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var updatePublisher: PassthroughSubject<State, Never>?
    private var updateQueue = DispatchQueue(label: "walletModel_update_queue")

    private let _state: CurrentValueSubject<State, Never> = .init(.created)
    private lazy var _rate: CurrentValueSubject<Rate, Never> = .init(.loading(cached: quotesRepository.quote(for: tokenItem)))

    private let _localPendingTransactionSubject: PassthroughSubject<Void, Never> = .init()
    private lazy var formatter = BalanceFormatter()

    // MARK: - Balance providers

    lazy var availableBalanceProvider = makeAvailableBalanceProvider()
    lazy var stakingBalanceProvider = makeStakingBalanceProvider()
    lazy var totalTokenBalanceProvider = makeTotalTokenBalanceProvider()

    lazy var fiatAvailableBalanceProvider = makeFiatAvailableBalanceProvider()
    lazy var fiatStakingBalanceProvider = makeFiatStakingBalanceProvider()
    lazy var fiatTotalTokenBalanceProvider = makeFiatTotalTokenBalanceProvider()

    deinit {
        AppLog.shared.debug("🗑 \(self) deinit")
    }

    init(
        walletManager: WalletManager,
        stakingManager: StakingManager?,
        transactionHistoryService: TransactionHistoryService?,
        amountType: Amount.AmountType,
        shouldPerformHealthCheck: Bool,
        isCustom: Bool,
        sendAvailabilityProvider: TransactionSendAvailabilityProvider,
        tokenBalancesRepository: TokenBalancesRepository
    ) {
        self.walletManager = walletManager
        _stakingManager = stakingManager
        _transactionHistoryService = transactionHistoryService
        self.amountType = amountType
        self.isCustom = isCustom
        self.sendAvailabilityProvider = sendAvailabilityProvider
        self.tokenBalancesRepository = tokenBalancesRepository

        bind()
        performHealthCheckIfNeeded(shouldPerform: shouldPerformHealthCheck)
    }

    private func bind() {
        walletManager.statePublisher
            .filter { !$0.isInitialState }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                self?.walletManagerDidUpdate(newState)
            }
            .store(in: &bag)

        quotesRepository
            .quotesPublisher
            .dropFirst() // we need to drop first value because it's an empty dictionary
            .map { [currencyId = tokenItem.currencyId] quotes in
                currencyId.flatMap { quotes[$0] }
            }
            .removeDuplicates()
            .sink { [weak self] quote in
                self?.updateQuote(quote: quote)
            }
            .store(in: &bag)
    }

    private func performHealthCheckIfNeeded(shouldPerform: Bool) {
        if shouldPerform {
            DispatchQueue.main.async {
                self.accountHealthChecker.performAccountCheckIfNeeded(self.wallet.address)
            }
        }
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

        if !silent {
            updateState(.loading)
        }

        updateWalletModelSubscription = walletManager
            .updatePublisher()
            .combineLatest(loadQuotes(), updateStakingManagerState()) { state, _, _ in state }
            .receive(on: updateQueue)
            .sink { [weak self] newState in
                guard let self else { return }

                updatePublisher?.send(mapState(newState))
                updatePublisher?.send(completion: .finished)
                updatePublisher = nil
            }

        return newUpdatePublisher.eraseToAnyPublisher()
    }

    func updateAfterSendingTransaction() {
        // Force update transactions history to take a new pending transaction from the local storage
        _localPendingTransactionSubject.send(())
        startUpdatingTimer()
    }

    // MARK: - State updates

    private func walletManagerDidUpdate(_ walletManagerState: WalletManagerState) {
        switch walletManagerState {
        case .loaded:
            if let demoBalance {
                walletManager.wallet.add(coinValue: demoBalance)
            }
        case .failed, .loading, .initial:
            break
        }

        updateState(mapState(walletManagerState))
    }

    private func mapState(_ walletManagerState: WalletManagerState) -> WalletModel.State {
        switch walletManagerState {
        case .loaded:
            if let balance = wallet.amounts[amountType]?.value {
                return .loaded(balance)
            }

            return .failed(error: WalletModelError.balanceNotFound.localizedDescription)
        case .failed(WalletError.noAccount(let message, let amountToCreate)):
            return .noAccount(message: message, amountToCreate: amountToCreate)
        case .failed(let error):
            return .failed(error: error.detailedError.localizedDescription)
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

    // MARK: - Quotes

    private func loadQuotes() -> AnyPublisher<Void, Never> {
        guard let currencyId = tokenItem.currencyId else {
            _rate.send(.custom)
            return .just(output: ())
        }

        return quotesRepository
            .loadQuotes(currencyIds: [currencyId])
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletModel, dict in
                walletModel.updateQuote(quote: dict[currencyId])
            })
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    private func updateQuote(quote: TokenQuote?) {
        if isCustom {
            _rate.send(.custom)
            return
        }

        if let quote {
            _rate.send(.loaded(quote))
            return
        }

        // Set to failure with saving cached value
        _rate.send(.failure(cached: rate.cached))
    }

    // MARK: - Timer

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

    /// A convenience wrapper for `AssetRequirementsManager.fulfillRequirements(for:signer:)`
    /// that automatically triggers the update of the internal state of this wallet model.
    func fulfillRequirements(signer: any TransactionSigner) -> some Publisher<Void, Error> {
        return assetRequirementsManager
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { walletModel, assetRequirementsManager in
                assetRequirementsManager.fulfillRequirements(for: walletModel.amountType, signer: signer)
            }
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .handleEvents(receiveOutput: { walletModel, _ in
                walletModel.updateAfterSendingTransaction()
            })
            .mapToVoid()
    }
}

// MARK: - Balance Provider

extension WalletModel {
    func makeAvailableBalanceProvider() -> TokenBalanceProvider {
        AvailableTokenBalanceProvider(walletModel: self, tokenBalancesRepository: tokenBalancesRepository)
    }

    func makeStakingBalanceProvider() -> TokenBalanceProvider {
        StakingTokenBalanceProvider(walletModel: self, tokenBalancesRepository: tokenBalancesRepository)
    }

    func makeTotalTokenBalanceProvider() -> TokenBalanceProvider {
        TotalTokenBalanceProvider(
            walletModel: self,
            availableBalanceProvider: availableBalanceProvider,
            stakingBalanceProvider: stakingBalanceProvider
        )
    }

    func makeFiatAvailableBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(walletModel: self, cryptoBalanceProvider: availableBalanceProvider)
    }

    func makeFiatStakingBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(walletModel: self, cryptoBalanceProvider: stakingBalanceProvider)
    }

    func makeFiatTotalTokenBalanceProvider() -> TokenBalanceProvider {
        FiatTokenBalanceProvider(walletModel: self, cryptoBalanceProvider: totalTokenBalanceProvider)
    }
}

// MARK: - Transaction history

extension WalletModel {
    func updateTransactionsHistory() -> AnyPublisher<Void, Never> {
        guard let _transactionHistoryService else {
            AppLog.shared.debug("TransactionsHistory for \(self) not supported")
            return .just(output: ())
        }

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

        AppLog.shared.debug("\(self) has pending local transactions. Try to insert it to transaction history")
        let mapper = PendingTransactionRecordMapper(formatter: formatter)

        pendingTransactions.forEach { pending in
            if items.contains(where: { $0.hash == pending.hash }) {
                AppLog.shared.debug("\(self) Transaction history already contains hash")
            } else {
                let record = mapper.mapToTransactionRecord(pending: pending)
                AppLog.shared.debug("\(self) Inserted to transaction history hash")
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

// MARK: - Staking

extension WalletModel {
    func updateStakingManagerState() -> AnyPublisher<Void, Never> {
        Future.async { [weak self] in
            await self?._stakingManager?.updateState(loadActions: true)
        }
        // Here we have to skip the error to let the PTR to complete
        .replaceError(with: ())
        .eraseToAnyPublisher()
    }
}

// MARK: - Interfaces

extension WalletModel {
    var blockchainDataProvider: BlockchainDataProvider {
        walletManager
    }

    var transactionValidator: TransactionValidator {
        walletManager
    }

    var transactionCreator: TransactionCreator {
        walletManager
    }

    var transactionSender: TransactionSender {
        walletManager
    }

    var bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator? {
        walletManager as? BitcoinTransactionFeeCalculator
    }

    var ethereumTransactionSigner: EthereumTransactionSigner? {
        walletManager as? EthereumTransactionSigner
    }

    var ethereumNetworkProvider: EthereumNetworkProvider? {
        walletManager as? EthereumNetworkProvider
    }

    var ethereumTransactionDataBuilder: EthereumTransactionDataBuilder? {
        walletManager as? EthereumTransactionDataBuilder
    }

    var signatureCountValidator: SignatureCountValidator? {
        walletManager as? SignatureCountValidator
    }

    var addressResolver: AddressResolver? {
        walletManager as? AddressResolver
    }

    var withdrawalNotificationProvider: WithdrawalNotificationProvider? {
        walletManager as? WithdrawalNotificationProvider
    }

    var hasRent: Bool {
        walletManager is RentProvider
    }

    var existentialDepositProvider: ExistentialDepositProvider? {
        walletManager as? ExistentialDepositProvider
    }

    var assetRequirementsManager: AssetRequirementsManager? {
        walletManager as? AssetRequirementsManager
    }

    var stakingManager: StakingManager? {
        _stakingManager
    }

    var stakeKitTransactionSender: StakeKitTransactionSender? {
        walletManager as? StakeKitTransactionSender
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

// MARK: - WalletModelError

enum WalletModelError: LocalizedError {
    case balanceNotFound

    var errorDescription: String? {
        switch self {
        case .balanceNotFound: "Balance not found"
        }
    }
}
