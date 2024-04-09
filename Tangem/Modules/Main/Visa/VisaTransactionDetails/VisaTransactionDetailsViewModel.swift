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
        transactionHistoryMapper.mapCommonTransactionInfo(from: transaction)
    }

    var cryptoRequests: [VisaTransactionDetailsView.CryptoRequestInfo] {
        transaction.requests.map { request in
            transactionHistoryMapper.mapCryptoRequestInfo(from: request, exploreAction: { [weak self] transactionHash in
                self?.exploreTransactionRequest(with: transactionHash)
            })
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

    private let transactionHistoryMapper: VisaTransactionHistoryMapper
    private let tokenItem: TokenItem
    private let transaction: VisaTransactionRecord

    init(tokenItem: TokenItem, transaction: VisaTransactionRecord) {
        self.tokenItem = tokenItem
        self.transaction = transaction
        transactionHistoryMapper = VisaTransactionHistoryMapper(currencySymbol: tokenItem.currencySymbol)
    }

    private func exploreTransactionRequest(with hash: TransactionHash) {
        let externalLinkProvider = ExternalLinkProviderFactory().makeProvider(for: tokenItem.blockchain)
        guard let url = externalLinkProvider.url(transaction: hash) else {
            return
        }

        safariManager.openURL(url)
    }
}
