//
//  ExpressInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSwapping
import BlockchainSdk

class ExpressInteractor {
    // MARK: - Public

    public var state: AnyPublisher<ExpressInteractorState, Never> {
        _state.eraseToAnyPublisher()
    }

    public var swappingPair: AnyPublisher<SwappingPair, Never> {
        _swappingPair.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let userWalletId: String
    private let initialWallet: WalletModel
    private let expressManager: ExpressManager
    private let allowanceProvider: ExpressAllowanceProvider
    private let feeProvider: ExpressFeeProvider
    private let expressRepository: ExpressRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressTransactionBuilder: ExpressTransactionBuilder
    private let signer: TransactionSigner
    private let logger: SwappingLogger

    // MARK: - Options

    private let _state: CurrentValueSubject<ExpressInteractorState, Never> = .init(.idle)
    private let _swappingPair: CurrentValueSubject<SwappingPair, Never>
    private let feeOption: ThreadSafeContainer<FeeOption> = .init(.market)

    private var updateStateTask: Task<Void, Error>?

    init(
        userWalletId: String,
        initialWallet: WalletModel,
        expressManager: ExpressManager,
        allowanceProvider: ExpressAllowanceProvider,
        feeProvider: ExpressFeeProvider,
        expressRepository: ExpressRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressTransactionBuilder: ExpressTransactionBuilder,
        signer: TransactionSigner,
        logger: SwappingLogger
    ) {
        self.userWalletId = userWalletId
        self.initialWallet = initialWallet
        self.expressManager = expressManager
        self.allowanceProvider = allowanceProvider
        self.feeProvider = feeProvider
        self.expressRepository = expressRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressTransactionBuilder = expressTransactionBuilder
        self.signer = signer
        self.logger = logger

        _swappingPair = .init(SwappingPair(sender: initialWallet, destination: .loading))
        initialLoading(wallet: initialWallet)
    }
}

// MARK: - Getters

extension ExpressInteractor {
    func getState() -> ExpressInteractorState {
        _state.value
    }

    func getSender() -> WalletModel {
        _swappingPair.value.sender
    }

    func getDestination() -> WalletModel? {
        _swappingPair.value.destination.value
    }

    func getFeeOption() -> FeeOption {
        feeOption.read()
    }

    // Proxy methods

    func getApprovePolicy() async -> SwappingApprovePolicy {
        await expressManager.getApprovePolicy()
    }

    func getAllProviders() async -> [ExpressAvailableProvider] {
        await expressManager.getAllProviders()
    }

    func getSelectedProvider() async -> ExpressAvailableProvider? {
        await expressManager.getSelectedProvider()
    }
}

// MARK: - Updates

extension ExpressInteractor {
    func swapPair() {
        guard let destination = getDestination() else {
            log("The destination not found")
            return
        }

        let newPair = SwappingPair(sender: destination, destination: .loaded(_swappingPair.value.sender))
        _swappingPair.value = newPair

        swappingPairDidChange()
    }

    func update(sender wallet: WalletModel) {
        log("Will update sender to \(wallet)")

        _swappingPair.value.sender = wallet
        swappingPairDidChange()
    }

    func update(destination wallet: WalletModel) {
        log("Will update destination to \(wallet)")

        _swappingPair.value.destination = .loaded(wallet)
        swappingPairDidChange()
    }

    func update(amount: Decimal?) {
        log("Will update amount to \(amount as Any)")

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.updateAmount(amount: amount)
            return try await interactor.mapState(state: state)
        }
    }

    func updateProvider(provider: ExpressAvailableProvider) {
        log("Will update provider to \(provider)")

        updateTask { interactor in
            let state = try await interactor.expressManager.updateSelectedProvider(provider: provider)
            return try await interactor.mapState(state: state)
        }
    }

    func updateApprovePolicy(policy: SwappingApprovePolicy) {
        updateState(.loading(type: .refreshRates))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(approvePolicy: policy)
            return try await interactor.mapState(state: state)
        }
    }

    func updateFeeOption(option: FeeOption) {
        feeOption.mutate { $0 = option }

        updateTask { interactor in
            try await interactor.feeOptionDidChange()
        }
    }
}

// MARK: - Send

extension ExpressInteractor {
    func send() async throws -> SentExpressTransactionData {
        guard let destination = getDestination() else {
            throw ExpressInteractorError.destinationNotFound
        }

        logSwapTransactionAnalyticsEvent()

        let result: TransactionSendResultState = try await {
            switch getState() {
            case .idle, .loading, .restriction:
                throw ExpressInteractorError.transactionDataNotFound
            case .permissionRequired:
                assertionFailure("Should called sendApproveTransaction()")
                throw ExpressInteractorError.transactionDataNotFound
            case .previewCEX(let state, _):
                guard let provider = await expressManager.getSelectedProvider() else {
                    throw ExpressInteractorError.providerNotFound
                }
                return try await sendCEXTransaction(state: state, provider: provider.provider)

            case .readyToSwap(let state, _):
                guard let provider = await expressManager.getSelectedProvider() else {
                    throw ExpressInteractorError.providerNotFound
                }
                return try await sendDEXTransaction(state: state, provider: provider.provider)
            }
        }()

        updateState(.idle)
        let sentTransactionData = SentExpressTransactionData(
            hash: result.hash,
            source: getSender(),
            destination: destination,
            fee: result.fee.amount.value,
            feeOption: getFeeOption(),
            provider: result.provider,
            date: Date(),
            expressTransactionData: result.data
        )

        expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData, userWalletId: userWalletId)
        return sentTransactionData
    }

    func sendApproveTransaction() async throws {
        guard case .permissionRequired(let state, _) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        guard let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        logApproveTransactionAnalyticsEvent(policy: state.policy)

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeApproveTransaction(
            wallet: sender,
            data: state.data,
            fee: fee
        )

        let result = try await sender.send(transaction, signer: signer).async()
        logger.debug("Sent the approve transaction with result: \(result)")
        allowanceProvider.didSendApproveTransaction(for: state.data.spender)
        updateState(.restriction(.hasPendingApproveTransaction, quote: getState().quote))
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: SwappingManagerRefreshType) {
        log("Was requested for refresh with \(type)")

        updateTask { interactor in
            interactor.log("Start refreshing task")
            interactor.updateState(.loading(type: type))

            // The type is full we can receive only from
            // the "Refresh" button on the error notification
            if type == .full {
                // If we have a restriction with destination after "refresh button"
                // Just show it
                if let restriction = await interactor.updatePairsAndLoadDestinationIfNeeded() {
                    return .restriction(restriction, quote: .none)
                }
            }

            let state = try await interactor.expressManager.update()
            return try await interactor.mapState(state: state)
        }
    }

    func cancelRefresh() {
        guard updateStateTask != nil else {
            return
        }

        log("Cancel the refreshing task")
        updateStateTask?.cancel()
        updateStateTask = nil
    }
}

// MARK: - State

private extension ExpressInteractor {
    func mapState(state: ExpressManagerState) async throws -> ExpressInteractorState {
        if hasPendingTransaction() {
            return .restriction(.hasPendingTransaction, quote: state.quote)
        }

        switch state {
        case .idle:
            return .idle

        case .restriction(.tooSmallAmount(let minAmount), let quote):
            return .restriction(.notEnoughAmountForSwapping(minAmount: minAmount), quote: quote)

        case .restriction(.approveTransactionInProgress, let quote):
            return .restriction(.hasPendingApproveTransaction, quote: quote)

        case .restriction(.insufficientBalance(let requiredAmount), let quote):
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: requiredAmount), quote: quote)

        case .permissionRequired(let permissionRequired):
            let permissionRequiredState = PermissionRequiredState(
                policy: permissionRequired.policy,
                data: permissionRequired.data,
                fees: mapToFees(fee: permissionRequired.fee)
            )
            let state: ExpressInteractorState = .permissionRequired(permissionRequiredState, quote: permissionRequired.quote)

            guard try await hasEnoughBalanceForFee(fees: permissionRequiredState.fees, amount: permissionRequired.quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: permissionRequired.quote)
            }

            return state

        case .previewCEX(let previewCEX):
            let previewCEXState = PreviewCEXState(subtractFee: previewCEX.subtractFee, fees: mapToFees(fee: previewCEX.fee))
            let state: ExpressInteractorState = .previewCEX(previewCEXState, quote: previewCEX.quote)

            guard try await hasEnoughBalanceForFee(fees: previewCEXState.fees, amount: previewCEX.quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: previewCEX.quote)
            }

            return state

        case .ready(let ready):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: ready.quote)
            }

            let readyToSwapState = ReadyToSwapState(data: ready.data, fees: mapToFees(fee: ready.fee))
            let state: ExpressInteractorState = .readyToSwap(readyToSwapState, quote: ready.quote)

            guard try await hasEnoughBalanceForFee(fees: readyToSwapState.fees, amount: ready.quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: ready.quote)
            }

            return state
        }
    }

    func updateState(_ state: ExpressInteractorState) {
        log("Update state to \(state)")

        if case .restriction(.notEnoughAmountForFee, _) = state {
            Analytics.log(
                event: .swapNoticeNotEnoughFee,
                params: [
                    .token: initialWallet.tokenItem.currencySymbol,
                    .blockchain: initialWallet.tokenItem.blockchain.displayName,
                ]
            )
        }

        _state.send(state)
    }
}

// MARK: - Restriction

private extension ExpressInteractor {
    func hasEnoughBalanceForFee(fees: [FeeOption: Fee], amount: Decimal?) async throws -> Bool {
        guard let fee = fees[getFeeOption()]?.amount.value else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()

        if sender.isToken {
            let coinBalance = try await sender.getCoinBalance()
            return fee <= coinBalance
        }

        guard let amount else {
            throw ExpressManagerError.amountNotFound
        }

        let balance = try await sender.getBalance()
        log("\(#function) fee: \(fee) amount: \(amount) balance: \(balance)")

        return fee + amount <= balance
    }

    func hasPendingTransaction() -> Bool {
        return getSender().hasPendingTransactions
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func sendDEXTransaction(state: ReadyToSwapState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        guard let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: state.data, fee: fee)
        let result = try await sender.send(transaction, signer: signer).async()

        return TransactionSendResultState(hash: result.hash, data: state.data, fee: fee, provider: provider)
    }

    func sendCEXTransaction(state: PreviewCEXState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        guard let fee = state.fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        let sender = getSender()
        let data = try await expressManager.requestData()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: data, fee: fee)
        let result = try await sender.send(transaction, signer: signer).async()

        return TransactionSendResultState(hash: result.hash, data: data, fee: fee, provider: provider)
    }
}

// MARK: - Changes

private extension ExpressInteractor {
    func swappingPairDidChange() {
        allowanceProvider.setup(wallet: getSender())
        feeProvider.setup(wallet: getSender())
        // Reset feeOption
        feeOption.mutate { $0 = .market }

        updateTask { interactor in
            guard let destination = interactor.getDestination() else {
                return .restriction(.noDestinationTokens, quote: .none)
            }

            // If we have a amount to we will start the full update
            if let amount = await interactor.expressManager.getAmount(), amount > 0 {
                interactor.updateState(.loading(type: .full))
            }

            let sender = interactor.getSender()
            let pair = ExpressManagerSwappingPair(source: sender, destination: destination)
            let state = try await interactor.expressManager.updatePair(pair: pair)
            return try await interactor.mapState(state: state)
        }
    }

    func feeOptionDidChange() async throws -> ExpressInteractorState {
        switch getState() {
        case .idle:
            return .idle
        case .loading(let type):
            return .loading(type: type)
        case .permissionRequired(let state, let quote):
            let state: ExpressInteractorState = .permissionRequired(state, quote: quote)

            guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: quote)
            }

            return state
        case .restriction(.notEnoughAmountForFee(let returnState), let quote):
            guard try await hasEnoughBalanceForFee(fees: returnState.fees, amount: quote?.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(returnState), quote: quote)
            }

            return returnState
        case .previewCEX(let state, let quote):
            let state: ExpressInteractorState = .previewCEX(state, quote: quote)

            guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: quote)
            }

            return state
        case .readyToSwap(let state, let quote):
            let state: ExpressInteractorState = .readyToSwap(state, quote: quote)

            guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                return .restriction(.notEnoughAmountForFee(state), quote: quote)
            }

            return state
        case .restriction:
            throw ExpressInteractorError.transactionDataNotFound
        }
    }
}

// MARK: - Helpers

private extension ExpressInteractor {
    func updateTask(block: @escaping (_ interactor: ExpressInteractor) async throws -> ExpressInteractorState) {
        cancelRefresh()
        updateStateTask = Task { [weak self] in
            guard let self else { return }

            do {
                let state = try await block(self)

                try Task.checkCancellation()

                updateState(state)
            } catch {
                if error is CancellationError || Task.isCancelled {
                    // Do nothing
                    log("The update task was cancelled")
                    return
                }

                if let error = error as? ExpressAPIError {
                    await logExpressError(error)
                }

                let quote = getState().quote
                updateState(.restriction(.requiredRefresh(occurredError: error), quote: quote))
            }
        }
    }

    func initialLoading(wallet: WalletModel) {
        updateTask { interactor in
            if let restriction = await interactor.loadDestination(wallet: wallet) {
                return .restriction(restriction, quote: .none)
            }

            return .idle
        }
    }

    func updatePairsAndLoadDestinationIfNeeded() async -> RestrictionType? {
        guard getDestination() == nil else {
            return nil
        }

        let wallet = getSender()
        return await loadDestination(wallet: wallet)
    }

    func loadDestination(wallet: WalletModel) async -> RestrictionType? {
        _swappingPair.value.destination = .loading

        do {
            try await expressRepository.updatePairs(for: wallet)
            let destination = try await expressDestinationService.getDestination(source: wallet)
            update(destination: destination)
            return nil
        } catch ExpressDestinationServiceError.destinationNotFound {
            Analytics.log(.swapNoticeNoAvailableTokensToSwap)
            log("Destination not found")
            _swappingPair.value.destination = .failedToLoad(error: ExpressDestinationServiceError.destinationNotFound)
            return .noDestinationTokens
        } catch {
            log("Get destination failed with error: \(error)")
            _swappingPair.value.destination = .failedToLoad(error: error)
            return .requiredRefresh(occurredError: error)
        }
    }

    func mapToFees(fee: ExpressFee) -> [FeeOption: Fee] {
        switch fee {
        case .single(let fee):
            return [.market: fee]
        case .double(let market, let priority):
            return [.market: market, .fast: priority]
        }
    }
}

// MARK: - Log

private extension ExpressInteractor {
    func log(_ args: Any) {
        logger.debug("[Express] \(self) \(args)")
    }
}

// MARK: - Analytics

private extension ExpressInteractor {
    func logSwapTransactionAnalyticsEvent() {
        var parameters: [Analytics.ParameterKey: String] = [.sendToken: getSender().tokenItem.currencySymbol]

        if let destination = getDestination() {
            parameters[.receiveToken] = destination.tokenItem.currencySymbol
        }

        Analytics.log(event: .swapButtonSwap, params: parameters)
    }

    func logApproveTransactionAnalyticsEvent(policy: SwappingApprovePolicy) {
        var parameters: [Analytics.ParameterKey: String] = [.sendToken: getSender().tokenItem.currencySymbol]

        switch policy {
        case .specified:
            parameters[.type] = Analytics.ParameterValue.oneTransactionApprove.rawValue
        case .unlimited:
            parameters[.type] = Analytics.ParameterValue.unlimitedApprove.rawValue
        }

        if let destination = getDestination() {
            parameters[.receiveToken] = destination.tokenItem.currencySymbol
        }

        Analytics.log(event: .swapButtonPermissionApprove, params: parameters)
    }

    func logExpressError(_ error: ExpressAPIError) async {
        var parameters: [Analytics.ParameterKey: String] = [
            .token: initialWallet.tokenItem.currencySymbol,
            .errorCode: error.errorCode.localizedDescription,
        ]

        if let provider = await getSelectedProvider() {
            parameters[.provider] = provider.provider.name
        }

        Analytics.log(event: .swapNoticeExpressError, params: parameters)
    }
}

// MARK: - CustomStringConvertible

extension ExpressInteractor: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Models

enum ExpressInteractorError: String, LocalizedError {
    case feeNotFound
    case quoteNotFound
    case transactionDataNotFound
    case destinationNotFound
    case providerNotFound
    case amountNotFound

    var errorDescription: String? {
        return rawValue
    }
}

extension ExpressInteractor {
    indirect enum ExpressInteractorState {
        case idle
        case loading(type: SwappingManagerRefreshType)
        case restriction(_ type: RestrictionType, quote: ExpressQuote?)
        case permissionRequired(PermissionRequiredState, quote: ExpressQuote)
        case previewCEX(PreviewCEXState, quote: ExpressQuote)
        case readyToSwap(ReadyToSwapState, quote: ExpressQuote)

        var fees: [FeeOption: Fee] {
            switch self {
            case .restriction(.notEnoughAmountForFee(.previewCEX(let state, _)), _):
                return state.fees
            case .restriction(.notEnoughAmountForFee(.readyToSwap(let state, _)), _):
                return state.fees
            case .restriction(.notEnoughAmountForFee(.permissionRequired(let state, _)), _):
                return state.fees
            case .permissionRequired(let state, _):
                return state.fees
            case .previewCEX(let state, _):
                return state.fees
            case .readyToSwap(let state, _):
                return state.fees
            case .idle, .loading, .restriction:
                return [:]
            }
        }

        var quote: ExpressQuote? {
            switch self {
            case .idle, .loading:
                return nil
            case .restriction(_, let quote):
                return quote
            case .readyToSwap(_, let quote), .previewCEX(_, let quote), .permissionRequired(_, let quote):
                return quote
            }
        }

        var isAvailableToSendTransaction: Bool {
            switch self {
            case .readyToSwap, .permissionRequired, .previewCEX:
                return true
            case .idle, .loading, .restriction:
                return false
            }
        }
    }

    // State models

    enum RestrictionType {
        case notEnoughAmountForSwapping(minAmount: Decimal)
        case hasPendingTransaction
        case hasPendingApproveTransaction
        case notEnoughBalanceForSwapping(requiredAmount: Decimal)
        case notEnoughAmountForFee(_ returnState: ExpressInteractorState)
        case requiredRefresh(occurredError: Error)
        case noDestinationTokens
    }

    struct PermissionRequiredState {
        let policy: SwappingApprovePolicy
        let data: ExpressApproveData
        let fees: [FeeOption: Fee]
    }

    struct PreviewCEXState {
        let subtractFee: Decimal
        let fees: [FeeOption: Fee]
    }

    struct ReadyToSwapState {
        let data: ExpressTransactionData
        let fees: [FeeOption: Fee]
    }

    // Manager models

    struct SwappingPair {
        var sender: WalletModel
        var destination: LoadingValue<WalletModel>
    }

    struct TransactionSendResultState {
        let hash: String
        let data: ExpressTransactionData
        let fee: Fee
        let provider: ExpressProvider
    }
}
