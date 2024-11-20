//
//  OnrampPendingTransactionRecord.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let txId: String
    let provider: Provider
    let fromAmount: Decimal
    let fromCurrencyCode: String
    let destinationTokenTxInfo: TokenTxInfo

    var transactionStatus: PendingOnrampTransactionStatus
}

extension OnrampPendingTransactionRecord {
    struct TokenTxInfo: Codable, Equatable {
        let tokenItem: TokenItem
        let amountString: String
        let isCustom: Bool

        var amount: Decimal {
            convertToDecimal(amountString)
        }
    }

    struct Provider: Codable, Equatable {
        let id: String
        let name: String
        let iconURL: URL?

        init(id: String, name: String, iconURL: URL?) {
            self.id = id
            self.name = name
            self.iconURL = iconURL
        }

        init(provider: ExpressProvider) {
            id = provider.id
            name = provider.name
            iconURL = provider.imageURL
        }
    }
}

private func convertToDecimal(_ str: String) -> Decimal {
    let decimalSeparator = Locale.posixEnUS.decimalSeparator ?? "."
    let cleanedStr = str.replacingOccurrences(of: ",", with: decimalSeparator)
    return Decimal(stringValue: cleanedStr) ?? 0
}
