//
//  DefaultExchangeManager.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 24.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultExchangeManager {
    // MARK: - Dependencies

    private let exchangeProvider: ExchangeProvider
    private let walletDataProvider: WalletDataProvider
    private let logger: ExchangeLogger
    private let referrer: ExchangeReferrerAccount?

    // MARK: - Internal

    private var availabilityState: ExchangeAvailabilityState = .idle

    private var exchangeItems: ExchangeItems {
        didSet { delegate?.exchangeManager(self, didUpdate: exchangeItems) }
    }

    private weak var delegate: ExchangeManagerDelegate?
    private var amount: Decimal?
    private var formattedAmount: String {
        guard let amount else { return "" }

        return String(describing: exchangeItems.source.convertToWEI(value: amount))
    }

    private var walletAddress: String? {
        walletDataProvider.getWalletAddress(currency: exchangeItems.source)
    }

    private var tokenExchangeAllowanceLimit: Decimal?
    // Cached addresses for check approving transactions
    private var pendingTransactions: [Currency: PendingTransactionState] = [:]
    private var bag: Set<AnyCancellable> = []
    private var refreshTask: Task<Void, Never>?

    init(
        exchangeProvider: ExchangeProvider,
        walletDataProvider: WalletDataProvider,
        logger: ExchangeLogger,
        referrer: ExchangeReferrerAccount?,
        exchangeItems: ExchangeItems,
        amount: Decimal? = nil
    ) {
        self.exchangeProvider = exchangeProvider
        self.walletDataProvider = walletDataProvider
        self.logger = logger
        self.referrer = referrer
        self.exchangeItems = exchangeItems
        self.amount = amount

        updateBalances()
    }
}

// MARK: - ExchangeManager

extension DefaultExchangeManager: ExchangeManager {
    func setDelegate(_ delegate: ExchangeManagerDelegate) {
        self.delegate = delegate
    }

    func getAvailabilityState() -> ExchangeAvailabilityState {
        return availabilityState
    }

    func getExchangeItems() -> ExchangeItems {
        return exchangeItems
    }

    func getReferrerAccount() -> ExchangeReferrerAccount? {
        return referrer
    }

    func isEnoughAllowance() -> Bool {
        guard exchangeItems.source.isToken, let amount, amount > 0 else {
            return true
        }

        guard let tokenExchangeAllowanceLimit else {
            return false
        }

        return amount <= tokenExchangeAllowanceLimit
    }

    func update(exchangeItems: ExchangeItems) {
        self.exchangeItems = exchangeItems
        exchangeItemsDidChange()
    }

    func update(amount: Decimal?) {
        self.amount = amount
        amountDidChange()
    }

    func refresh(type: ExchangeManagerRefreshType) {
        refreshTask?.cancel()
        refreshTask = nil
        if let amount = amount, amount > 0 {
            refreshValues(refreshType: type)
        } else {
            updateState(.idle)
        }
    }

    func didSendApprovingTransaction(exchangeTxData: ExchangeTransactionDataModel) {
        pendingTransactions[exchangeTxData.sourceCurrency] = .pending(destination: exchangeTxData.destinationAddress)
        tokenExchangeAllowanceLimit = nil

        refresh(type: .full)
    }

    func didSendSwapTransaction(exchangeTxData: ExchangeTransactionDataModel) {
        updateState(.idle)
    }
}

// MARK: - Fields Changes

private extension DefaultExchangeManager {
    func amountDidChange() {
        updateBalances()

        refresh(type: .full)
    }

    func exchangeItemsDidChange() {
        updateState(.idle)
        updateBalances()

        tokenExchangeAllowanceLimit = nil
    }
}

// MARK: - State updates

private extension DefaultExchangeManager {
    func updateState(_ state: ExchangeAvailabilityState) {
        availabilityState = state
        if Task.isCancelled {
            // Task was cancelled so we don't need to update UI for staled refresh request
            return
        }
        delegate?.exchangeManager(self, didUpdate: state)
    }
}

// MARK: - Requests

private extension DefaultExchangeManager {
    func refreshValues(refreshType: ExchangeManagerRefreshType = .full) {
        updateState(.loading(refreshType))

        refreshTask = Task {
            do {
                let quoteData = try await getQuoteDataModel()
                let preview = try mapPreviewSwappingDataModel(from: quoteData)

                try Task.checkCancellation()

                switch exchangeItems.source.currencyType {
                case .coin:
                    try await loadExchangeData(preview: preview)

                case .token:
                    guard preview.isEnoughAmountForExchange else {
                        updateState(.preview(preview))
                        return
                    }

                    await updateExchangeAmountAllowance()

                    // Check if permission required
                    guard !isEnoughAllowance() else {
                        try await loadExchangeData(preview: preview)
                        return
                    }

                    try await loadApproveData(preview: preview, quoteData: quoteData)
                }
            } catch {
                if Task.isCancelled {
                    return
                }

                updateState(.requiredRefresh(occurredError: error))
            }
        }
    }

    func loadExchangeData(preview: PreviewSwappingDataModel) async throws {
        guard preview.isEnoughAmountForExchange else {
            updateState(.preview(preview))
            return
        }

        let exchangeData = try await getExchangeTxDataModel()

        try Task.checkCancellation()

        let info = try mapToExchangeTransactionInfo(exchangeData: exchangeData)
        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)

        try Task.checkCancellation()

        updateState(.available(result, info: info))
    }

    func loadApproveData(preview: PreviewSwappingDataModel, quoteData: QuoteDataModel) async throws {
        // If approving transaction isn't send
        if preview.hasPendingTransaction {
            await updateExchangeAmountAllowance()

            if isEnoughAllowance() {
                /// If we get enough allowance
                pendingTransactions[exchangeItems.source] = nil
                refreshValues()
            } else {
                updateState(.preview(preview))
            }

            return
        }

        let approvedDataModel = try await getExchangeApprovedDataModel()
        let info = try mapToExchangeTransactionInfo(
            quoteData: quoteData,
            approvedData: approvedDataModel
        )

        let result = try await mapToSwappingResultDataModel(preview: preview, transaction: info)
        updateState(.available(result, info: info))
    }

    func updateExchangeAmountAllowance() async {
        // If allowance limit already loaded just call delegate method
        guard let walletAddress else {
            return
        }

        do {
            tokenExchangeAllowanceLimit = try await exchangeProvider.fetchAmountAllowance(
                for: exchangeItems.source,
                walletAddress: walletAddress
            )

            logger.debug("Token \(exchangeItems.source) allowanceLimit \(tokenExchangeAllowanceLimit as Any)")
        } catch {
            tokenExchangeAllowanceLimit = nil
            updateState(.requiredRefresh(occurredError: error))
        }
    }

    func getQuoteDataModel() async throws -> QuoteDataModel {
        try await exchangeProvider.fetchQuote(
            items: exchangeItems,
            amount: formattedAmount
        )
    }

    func getExchangeApprovedDataModel() async throws -> ExchangeApprovedDataModel {
        try await exchangeProvider.fetchApproveExchangeData(for: exchangeItems.source)
    }

    func getExchangeTxDataModel() async throws -> ExchangeDataModel {
        guard let walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        return try await exchangeProvider.fetchExchangeData(
            items: exchangeItems,
            walletAddress: walletAddress,
            amount: formattedAmount,
            referrer: referrer
        )
    }

    func updateBalances() {
        Task {
            let source = exchangeItems.source
            let balance = try await walletDataProvider.getBalance(for: source)

            if let destination = exchangeItems.destination {
                let balance = try await walletDataProvider.getBalance(for: destination)
                if exchangeItems.destinationBalance != balance {
                    exchangeItems.destinationBalance = balance
                }
            }

            if exchangeItems.sourceBalance != balance {
                exchangeItems.sourceBalance = balance
            }
        }
    }
}

// MARK: - Mapping

private extension DefaultExchangeManager {
    func mapPreviewSwappingDataModel(from quoteData: QuoteDataModel) throws -> PreviewSwappingDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        let paymentAmount = exchangeItems.source.convertFromWEI(value: quoteData.fromTokenAmount)
        let expectedAmount = destination.convertFromWEI(value: quoteData.toTokenAmount)
        let hasPendingTransaction = pendingTransactions[exchangeItems.source] != nil
        let isEnoughAmountForExchange = exchangeItems.sourceBalance >= paymentAmount

        return PreviewSwappingDataModel(
            expectedAmount: expectedAmount,
            isPermissionRequired: !isEnoughAllowance(),
            hasPendingTransaction: hasPendingTransaction,
            isEnoughAmountForExchange: isEnoughAmountForExchange
        )
    }

    func mapToSwappingResultDataModel(
        preview: PreviewSwappingDataModel,
        transaction: ExchangeTransactionDataModel
    ) async throws -> SwappingResultDataModel {
        let source = exchangeItems.source
        let sourceBalance = exchangeItems.sourceBalance
        let fee = transaction.fee

        let isEnoughAmountForFee: Bool
        var paymentAmount = transaction.sourceCurrency.convertFromWEI(value: transaction.sourceAmount)
        let receivedAmount = transaction.destinationCurrency.convertFromWEI(value: transaction.destinationAmount)
        switch exchangeItems.source.currencyType {
        case .coin:
            paymentAmount += fee
            isEnoughAmountForFee = sourceBalance >= fee
        case .token:
            let coinBalance = try await walletDataProvider.getBalance(for: source.blockchain)
            isEnoughAmountForFee = coinBalance >= fee
        }

        let isEnoughAmountForExchange = sourceBalance >= paymentAmount

        return SwappingResultDataModel(
            amount: receivedAmount,
            fee: fee,
            isEnoughAmountForExchange: isEnoughAmountForExchange,
            isEnoughAmountForFee: isEnoughAmountForFee,
            isPermissionRequired: !isEnoughAllowance()
        )
    }

    func mapToExchangeTransactionInfo(exchangeData: ExchangeDataModel) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
            sourceBlockchain: exchangeItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: exchangeData.sourceAddress,
            destinationAddress: exchangeData.destinationAddress,
            txData: exchangeData.txData,
            sourceAmount: exchangeData.sourceCurrencyAmount,
            destinationAmount: exchangeData.destinationCurrencyAmount,
            value: exchangeData.value,
            gasValue: exchangeData.gas,
            gasPrice: exchangeData.gasPrice
        )
    }

    func mapToExchangeTransactionInfo(
        quoteData: QuoteDataModel,
        approvedData: ExchangeApprovedDataModel
    ) throws -> ExchangeTransactionDataModel {
        guard let destination = exchangeItems.destination else {
            throw ExchangeManagerError.destinationNotFound
        }

        guard let walletAddress = walletAddress else {
            throw ExchangeManagerError.walletAddressNotFound
        }

        return ExchangeTransactionDataModel(
            sourceCurrency: exchangeItems.source,
            sourceBlockchain: exchangeItems.source.blockchain,
            destinationCurrency: destination,
            sourceAddress: walletAddress,
            destinationAddress: approvedData.tokenAddress,
            txData: approvedData.data,
            sourceAmount: quoteData.fromTokenAmount,
            destinationAmount: quoteData.toTokenAmount,
            value: approvedData.value,
            gasValue: quoteData.estimatedGas,
            gasPrice: approvedData.gasPrice
        )
    }
}

extension DefaultExchangeManager {
    enum PendingTransactionState: Hashable {
        case pending(destination: String)
    }
}
