//
//  ExpressInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress
import BlockchainSdk

class ExpressInteractor {
    // MARK: - Public

    public var state: AnyPublisher<State, Never> {
        _state.eraseToAnyPublisher()
    }

    public var swappingPair: AnyPublisher<SwappingPair, Never> {
        _swappingPair.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let userWalletId: String
    private let initialWallet: WalletModel
    private let destinationWallet: WalletModel?
    private let expressManager: ExpressManager
    private let allowanceProvider: UpdatableAllowanceProvider
    private let feeProvider: ExpressFeeProvider
    private let expressRepository: ExpressRepository
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let expressDestinationService: ExpressDestinationService
    private let expressTransactionBuilder: ExpressTransactionBuilder
    private let expressAPIProvider: ExpressAPIProvider
    private let signer: TangemSigner
    private let logger: Logger

    // MARK: - Options

    private let _state: CurrentValueSubject<State, Never> = .init(.idle)
    private let _swappingPair: CurrentValueSubject<SwappingPair, Never>
    private let feeOption: ThreadSafeContainer<FeeOption> = .init(.market)

    private var updateStateTask: Task<Void, Error>?

    init(
        userWalletId: String,
        initialWallet: WalletModel,
        destinationWallet: WalletModel?,
        expressManager: ExpressManager,
        allowanceProvider: UpdatableAllowanceProvider,
        feeProvider: ExpressFeeProvider,
        expressRepository: ExpressRepository,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        expressDestinationService: ExpressDestinationService,
        expressTransactionBuilder: ExpressTransactionBuilder,
        expressAPIProvider: ExpressAPIProvider,
        signer: TangemSigner,
        logger: Logger
    ) {
        self.userWalletId = userWalletId
        self.initialWallet = initialWallet
        self.destinationWallet = destinationWallet
        self.expressManager = expressManager
        self.allowanceProvider = allowanceProvider
        self.feeProvider = feeProvider
        self.expressRepository = expressRepository
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.expressDestinationService = expressDestinationService
        self.expressTransactionBuilder = expressTransactionBuilder
        self.expressAPIProvider = expressAPIProvider
        self.signer = signer
        self.logger = logger

        _swappingPair = .init(
            SwappingPair(
                sender: initialWallet,
                destination: { () -> LoadingValue<WalletModel> in
                    if let destinationWallet {
                        return .loaded(destinationWallet)
                    }

                    return .loading
                }()
            )
        )

        initialLoading(wallet: initialWallet)
    }
}

// MARK: - Getters

extension ExpressInteractor {
    func getState() -> State {
        _state.value
    }

    func getSender() -> WalletModel {
        _swappingPair.value.sender
    }

    func getDestination() -> WalletModel? {
        _swappingPair.value.destination.value
    }

    func getDestinationValue() -> LoadingValue<WalletModel> {
        _swappingPair.value.destination
    }

    func getFeeOption() -> FeeOption {
        feeOption.read()
    }

    // Proxy methods

    func getApprovePolicy() async -> ExpressApprovePolicy {
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

    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) {
        log("Will update amount to \(amount as Any)")

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.updateAmount(amount: amount, by: source)
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

    func updateApprovePolicy(policy: ExpressApprovePolicy) {
        updateState(.loading(type: .refreshRates))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(approvePolicy: policy)
            return try await interactor.mapState(state: state)
        }
    }

    func updateFeeOption(option: FeeOption) {
        feeOption.mutate { $0 = option }

        let expressFeeOption: ExpressFeeOption = {
            switch option {
            case .market, .custom, .slow: .market
            case .fast: .fast
            }
        }()

        updateState(.loading(type: .full))
        updateTask { interactor in
            let state = try await interactor.expressManager.update(feeOption: expressFeeOption)
            return try await interactor.mapState(state: state)

//            try await interactor.feeOptionDidChange()
        }
    }
}

// MARK: - ApproveViewModelInput

extension ExpressInteractor: ApproveViewModelInput {
    var approveFeeValue: LoadingValue<Fee> {
        mapToApproveFeeLoadingValue(state: getState()) ?? .failedToLoad(error: CommonError.noData)
    }

    var approveFeeValuePublisher: AnyPublisher<LoadingValue<BlockchainSdk.Fee>, Never> {
        state
            .withWeakCaptureOf(self)
            .compactMap { interactor, state in
                interactor.mapToApproveFeeLoadingValue(state: state)
            }
            .eraseToAnyPublisher()
    }

    private func mapToApproveFeeLoadingValue(state: ExpressInteractor.State) -> LoadingValue<BlockchainSdk.Fee>? {
        switch state {
        case .permissionRequired(let state, _):
            guard let fee = state.fees[getFeeOption()] else {
                return .failedToLoad(error: ExpressInteractorError.feeNotFound)
            }

            return .loaded(fee)
        case .loading:
            return .loading
        case .restriction(.requiredRefresh(let error), _):
            return .failedToLoad(error: error)
        default:
            return nil
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

        // Ignore error here
        let expressSentResult = ExpressTransactionSentResult(hash: result.hash, source: getSender(), data: result.data)
        try? await expressAPIProvider.exchangeSent(result: expressSentResult)

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

        logTransactionSentAnalyticsEvent(data: sentTransactionData, signerType: result.signerType)
        expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData, userWalletId: userWalletId)

        return sentTransactionData
    }

    func sendApproveTransaction() async throws {
        guard case .permissionRequired(let state, _) = getState() else {
            throw ExpressInteractorError.transactionDataNotFound
        }

        let fee = try selectedFee(fees: state.fees)

        logApproveTransactionAnalyticsEvent(policy: state.policy)

        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeApproveTransaction(
            wallet: sender,
            data: state.data,
            fee: fee
        )

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))
        logger.debug("Sent the approve transaction with result: \(result)")
        allowanceProvider.didSendApproveTransaction(for: state.data.spender)
        logApproveTransactionSentAnalyticsEvent(policy: state.policy, signerType: result.signerType)
        updateState(.restriction(.hasPendingApproveTransaction, quote: getState().quote))
    }
}

// MARK: - Refresh

extension ExpressInteractor {
    func refresh(type: ExpressInteractor.RefreshType) {
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

            let state = try await interactor.expressManager.update(by: .autoUpdate)
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
    func mapState(state: ExpressManagerState) async throws -> State {
        switch state {
        case .idle:
            return .idle

        case .restriction(.tooSmallAmount(let minAmount), let quote):
            return .restriction(.tooSmallAmountForSwapping(minAmount: minAmount), quote: quote)

        case .restriction(.tooBigAmount(let maxAmount), let quote):
            return .restriction(.tooBigAmountForSwapping(maxAmount: maxAmount), quote: quote)

        case .restriction(.approveTransactionInProgress, let quote):
            return .restriction(.hasPendingApproveTransaction, quote: quote)

        case .restriction(.insufficientBalance(let requiredAmount), let quote):
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: requiredAmount), quote: quote)

        case .restriction(.feeCurrencyHasZeroBalance, let quote):
            return .restriction(.notEnoughAmountForFee(.idle), quote: quote)

        case .restriction(.feeCurrencyInsufficientBalanceForTxValue(let fee), let quote):
            return .restriction(.notEnoughAmountForTxValue(fee), quote: quote)

        case .permissionRequired(let permissionRequired):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: permissionRequired.quote)
            }

            return try await map(permissionRequired: permissionRequired)

        case .previewCEX(let previewCEX):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: previewCEX.quote)
            }

            return try await map(previewCEX: previewCEX)

        case .ready(let ready):
            if hasPendingTransaction() {
                return .restriction(.hasPendingTransaction, quote: ready.quote)
            }

            return try await map(ready: ready)
        }
    }

    func updateState(_ state: State) {
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
    func hasEnoughBalanceForFee(fees: [FeeOption: Fee], amount: Decimal) async throws -> Bool {
        let fee = try selectedFee(fees: fees)

        do {
            let transactionValidator = getSender().transactionValidator
            let amount = makeAmount(value: amount)
            try await transactionValidator.validate(amount: amount, fee: fee, destination: .generate)
            return true
        } catch ValidationError.feeExceedsBalance {
            return false
        } catch {
            return true
        }
    }

    func hasPendingTransaction() -> Bool {
        if case .hasPendingTransaction = getSender().sendingRestrictions {
            return true
        }

        return false
    }

    func map(permissionRequired: ExpressManagerState.PermissionRequired) async throws -> State {
        let fees = mapToFees(fee: .single(permissionRequired.data.fee))
        let amount = makeAmount(value: permissionRequired.quote.fromAmount)
        let fee = try selectedFee(fees: fees)

        let permissionRequiredState = PermissionRequiredState(
            policy: permissionRequired.policy,
            data: permissionRequired.data,
            fees: fees
        )
        let correctState: State = .permissionRequired(permissionRequiredState, quote: permissionRequired.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(ready: ExpressManagerState.Ready) async throws -> State {
        let fees = mapToFees(fee: ready.fee)
        let fee = try selectedFee(fees: fees)
        let amount = makeAmount(value: ready.quote.fromAmount)

        let readyToSwapState = ReadyToSwapState(data: ready.data, fees: fees)
        let correctState: State = .readyToSwap(readyToSwapState, quote: ready.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func map(previewCEX: ExpressManagerState.PreviewCEX) async throws -> State {
        let fees = mapToFees(fee: previewCEX.fee)
        let fee = try selectedFee(fees: fees)
        let amount = makeAmount(value: previewCEX.quote.fromAmount)

        let withdrawalNotificationProvider = getSender().withdrawalNotificationProvider
        let notification = withdrawalNotificationProvider?.withdrawalNotification(amount: amount, fee: fee)

        // Check on the minimum received amount
        // Almost impossible case because the providers check it on their side
        if let destination = getDestination(),
           case .noAccount(_, let amount) = destination.state,
           previewCEX.quote.expectAmount < amount {
            return .restriction(
                .notEnoughReceivedAmount(minAmount: amount, tokenSymbol: destination.tokenItem.currencySymbol),
                quote: previewCEX.quote
            )
        }

        let previewCEXState = PreviewCEXState(subtractFee: previewCEX.subtractFee, fees: fees, notification: notification)
        let correctState: State = .previewCEX(previewCEXState, quote: previewCEX.quote)

        return await validate(amount: amount, fee: fee, correctState: correctState)
    }

    func validate(amount: Amount, fee: Fee, correctState: State) async -> State {
        do {
            let transactionValidator = getSender().transactionValidator
            try await transactionValidator.validate(amount: amount, fee: fee, destination: .generate)
        } catch ValidationError.totalExceedsBalance, ValidationError.amountExceedsBalance {
            return .restriction(.notEnoughBalanceForSwapping(requiredAmount: amount.value), quote: correctState.quote)
        } catch ValidationError.feeExceedsBalance {
            return .restriction(.notEnoughAmountForFee(correctState), quote: correctState.quote)
        } catch let error as ValidationError {
            let context = ValidationErrorContext(isFeeCurrency: fee.amount.type == amount.type, feeValue: fee.amount.value)
            return .restriction(.validationError(error: error, context: context), quote: correctState.quote)
        } catch {
            return .restriction(.requiredRefresh(occurredError: error), quote: correctState.quote)
        }

        return correctState
    }
}

// MARK: - Swap

private extension ExpressInteractor {
    func sendDEXTransaction(state: ReadyToSwapState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let fee = try selectedFee(fees: state.fees)
        let sender = getSender()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: state.data, fee: fee)

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        return TransactionSendResultState(hash: result.hash, signerType: result.signerType, data: state.data, fee: fee, provider: provider)
    }

    func sendCEXTransaction(state: PreviewCEXState, provider: ExpressProvider) async throws -> TransactionSendResultState {
        let fee = try selectedFee(fees: state.fees)
        let sender = getSender()
        let data = try await expressManager.requestData()

        let factory = TransactionDispatcherFactory(walletModel: sender, signer: signer)
        let transactionDispatcher = factory.makeSendDispatcher()
        let transaction = try await expressTransactionBuilder.makeTransaction(wallet: sender, data: data, fee: fee)
        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        return TransactionSendResultState(hash: result.hash, signerType: result.signerType, data: data, fee: fee, provider: provider)
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

            // If we have an amount to we will start the full update
            if let amount = await interactor.expressManager.getAmount(), amount > 0 {
                interactor.updateState(.loading(type: .full))
            }

            let sender = interactor.getSender()
            let pair = ExpressManagerSwappingPair(source: sender, destination: destination)
            let state = try await interactor.expressManager.updatePair(pair: pair)
            return try await interactor.mapState(state: state)
        }
    }
    /*
     func feeOptionDidChange() async throws -> State {
         switch getState() {
         case .idle:
             return .idle
         case .loading(let type):
             return .loading(type: type)
         case .permissionRequired(let state, let quote):
             let state: State = .permissionRequired(state, quote: quote)

             guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                 return .restriction(.notEnoughAmountForFee(state), quote: quote)
             }

             return state
         case .restriction(.notEnoughAmountForFee(let returnState), let quote):
             guard let amount = quote?.fromAmount else {
                 throw ExpressManagerError.amountNotFound
             }

             guard try await hasEnoughBalanceForFee(fees: returnState.fees, amount: amount) else {
                 return .restriction(.notEnoughAmountForFee(returnState), quote: quote)
             }

             return returnState
         case .previewCEX(let state, let quote):
             let state: State = .previewCEX(state, quote: quote)

             guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                 return .restriction(.notEnoughAmountForFee(state), quote: quote)
             }

             return state
         case .readyToSwap(let state, let quote):
             let state: State = .readyToSwap(state, quote: quote)

             guard try await hasEnoughBalanceForFee(fees: state.fees, amount: quote.fromAmount) else {
                 return .restriction(.notEnoughAmountForFee(state), quote: quote)
             }

             return state
         case .restriction:
             throw ExpressInteractorError.transactionDataNotFound
         }
     }
     */
}

// MARK: - Helpers

private extension ExpressInteractor {
    func updateTask(block: @escaping (_ interactor: ExpressInteractor) async throws -> State) {
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
            if let restriction = await interactor.initialLoading(wallet: wallet) {
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
        return await initialLoading(wallet: wallet)
    }

    func initialLoading(wallet: WalletModel) async -> RestrictionType? {
        do {
            try await expressRepository.updatePairs(for: wallet)

            if _swappingPair.value.destination.value == nil {
                _swappingPair.value.destination = .loading
                let destination = try await expressDestinationService.getDestination(source: wallet)
                update(destination: destination)
            } else {
                swappingPairDidChange()
            }

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

    func selectedFee(fees: [FeeOption: Fee]) throws -> Fee {
        guard let fee = fees[getFeeOption()] else {
            throw ExpressInteractorError.feeNotFound
        }

        return fee
    }

    func makeAmount(value: Decimal) -> Amount {
        let wallet = getSender()
        return Amount(with: wallet.tokenItem.blockchain, type: wallet.amountType, value: value)
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

    func logApproveTransactionAnalyticsEvent(policy: ExpressApprovePolicy) {
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

    func logTransactionSentAnalyticsEvent(data: SentExpressTransactionData, signerType: String) {
        let analyticsFeeType: Analytics.ParameterValue = {
            if getState().fees.count == 1 {
                return .transactionFeeFixed
            }

            return data.feeOption.analyticsValue
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.swap.rawValue,
            .token: data.source.tokenItem.currencySymbol,
            .blockchain: data.source.tokenItem.blockchain.displayName,
            .feeType: analyticsFeeType.rawValue,
            .walletForm: signerType,
        ])
    }

    func logApproveTransactionSentAnalyticsEvent(policy: ExpressApprovePolicy, signerType: String) {
        let permissionType: Analytics.ParameterValue = {
            switch policy {
            case .specified:
                return .oneTransactionApprove
            case .unlimited:
                return .unlimitedApprove
            }
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: Analytics.ParameterValue.transactionFeeMax.rawValue,
            .token: getSender().tokenItem.currencySymbol,
            .blockchain: getSender().tokenItem.blockchain.displayName,
            .permissionType: permissionType.rawValue,
            .walletForm: signerType,
        ])
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
    indirect enum State {
        case idle
        case loading(type: RefreshType)
        case restriction(RestrictionType, quote: ExpressQuote?)
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

    enum RefreshType {
        case full
        case refreshRates
        case fee
    }

    enum RestrictionType {
        case tooSmallAmountForSwapping(minAmount: Decimal)
        case tooBigAmountForSwapping(maxAmount: Decimal)
        case hasPendingTransaction
        case hasPendingApproveTransaction
        case notEnoughBalanceForSwapping(requiredAmount: Decimal)
        case notEnoughAmountForFee(_ returnState: State)
        case notEnoughAmountForTxValue(_ estimatedTxValue: Decimal)
        case requiredRefresh(occurredError: Error)
        case noDestinationTokens
        case validationError(error: ValidationError, context: ValidationErrorContext)
        case notEnoughReceivedAmount(minAmount: Decimal, tokenSymbol: String)
    }

    struct PermissionRequiredState {
        let policy: ExpressApprovePolicy
        let data: ApproveTransactionData
        let fees: [FeeOption: Fee]
    }

    struct PreviewCEXState {
        let subtractFee: Decimal
        let fees: [FeeOption: Fee]
        let notification: WithdrawalNotification?
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
        let signerType: String
        let data: ExpressTransactionData
        let fee: Fee
        let provider: ExpressProvider
    }
}
