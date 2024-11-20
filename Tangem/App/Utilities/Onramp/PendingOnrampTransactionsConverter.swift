//
//  PendingOnrampTransactionsConverter.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PendingOnrampTransactionsConverter {
    func convertToTokenDetailsPendingTxInfo(_ transactions: [PendingOnrampTransaction], tapAction: @escaping (String) -> Void) -> [PendingExpressTransactionView.Info] {
        let iconBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()
        let iconURLBuilder = IconURLBuilder()

        return transactions.compactMap { transaction in
            let record = transaction.transactionRecord
            let destinationTokenItem = record.destinationTokenTxInfo.tokenItem

            let state: PendingExpressTransactionView.State
            switch record.transactionStatus {
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser, .done, .refunded:
                state = .inProgress
            case .failed, .canceled, .unknown, .paused:
                state = .error
            case .verificationRequired, .awaitingHash:
                state = .warning
            }

            return PendingExpressTransactionView.Info(
                id: transaction.transactionRecord.txId,
                title: "Buying \(destinationTokenItem.name)", // TODO: Move to localization https://tangem.atlassian.net/browse/IOS-8363
                sourceIconInfo: .init(
                    name: record.fromCurrencyCode,
                    blockchainIconName: nil,
                    imageURL: iconURLBuilder.fiatIconURL(currencyCode: record.fromCurrencyCode),
                    isCustom: false,
                    customTokenColor: nil
                ),
                sourceAmountText: balanceFormatter.formatFiatBalance(record.fromAmount, currencyCode: record.fromCurrencyCode),
                destinationIconInfo: iconBuilder.build(from: destinationTokenItem, isCustom: false),
                destinationCurrencySymbol: destinationTokenItem.currencySymbol,
                state: state,
                action: tapAction
            )
        }
    }
}
