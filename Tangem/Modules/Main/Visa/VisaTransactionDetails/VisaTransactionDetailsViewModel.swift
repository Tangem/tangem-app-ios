//
//  VisaTransactionDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 26/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemVisa

class VisaTransactionDetailsViewModel: ObservableObject, Identifiable {
    typealias TransactionHash = String

    // Exception. This should be in the coordinator.
    @Injected(\.safariManager) private var safariManager: SafariManager

    var fiatTransactionInfo: VisaTransactionDetailsView.CommonTransactionInfo {
        .init(
            idTitle: .id,
            transactionId: "\(transaction.id)",
            date: dateFormatter.string(from: transaction.date ?? Date()),
            type: transaction.type,
            status: transaction.status,
            blockchainAmount: balanceFormatter.formatCryptoBalance(transaction.blockchainAmount, currencyCode: tokenItem.currencySymbol),
            blockchainFee: balanceFormatter.formatCryptoBalance(transaction.blockchainFee, currencyCode: tokenItem.currencySymbol),
            transactionAmount: balanceFormatter.formatFiatBalance(transaction.transactionAmount, numericCurrencyCode: transaction.transactionCurrencyCode),
            currencyCode: iso4217CodeConverter.convertToStringCode(numericCode: transaction.transactionCurrencyCode) ?? "\(transaction.transactionCurrencyCode)"
        )
    }

    var cryptoRequests: [VisaTransactionDetailsView.CryptoRequestInfo] {
        transaction.requests.map { request in
            let commonInfo = VisaTransactionDetailsView.CommonTransactionInfo(
                idTitle: .requestId,
                transactionId: "\(request.id)",
                date: dateFormatter.string(from: request.date),
                type: request.type,
                status: request.status,
                blockchainAmount: balanceFormatter.formatCryptoBalance(request.blockchainAmount, currencyCode: tokenItem.currencySymbol),
                blockchainFee: balanceFormatter.formatCryptoBalance(request.blockchainFee, currencyCode: tokenItem.currencySymbol),
                transactionAmount: balanceFormatter.formatFiatBalance(request.transactionAmount, numericCurrencyCode: request.transactionCurrencyCode),
                currencyCode: iso4217CodeConverter.convertToStringCode(numericCode: request.transactionCurrencyCode) ?? "\(request.transactionCurrencyCode)"
            )

            let exploreAction: (() -> Void)?
            let hashToDisplay: String
            if let transactionHash = request.transactionHash {
                hashToDisplay = transactionHash
                exploreAction = { [weak self] in
                    self?.exploreTransactionRequest(with: hashToDisplay)
                }
            } else {
                exploreAction = nil
                hashToDisplay = AppConstants.dashSign
            }

            return .init(
                commonTransactionInfo: commonInfo,
                errorCode: "\(request.errorCode)",
                hash: hashToDisplay,
                status: request.status,
                exploreAction: exploreAction
            )
        }
    }

    var merchantName: String {
        transaction.merchantName ?? .unknown
    }

    var merchantCity: String {
        transaction.merchantCity ?? .unknown
    }

    var merchantCountryCode: String {
        transaction.merchantCountryCode ?? .unknown
    }

    var merchantCategoryCode: String {
        guard let code = transaction.merchantCategoryCode else {
            return .unknown
        }

        return "\(code)"
    }

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return dateFormatter
    }()

    private let iso4217CodeConverter = ISO4217CodeConverter.shared
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()
    private let tokenItem: TokenItem
    private let transaction: VisaTransactionRecord

    init(tokenItem: TokenItem, transaction: VisaTransactionRecord) {
        self.tokenItem = tokenItem
        self.transaction = transaction
    }

    private func exploreTransactionRequest(with hash: TransactionHash) {
        let externalLinkProvider = ExternalLinkProviderFactory().makeProvider(for: tokenItem.blockchain)
        guard let url = externalLinkProvider.url(transaction: hash) else {
            return
        }

        safariManager.openURL(url)
    }
}
