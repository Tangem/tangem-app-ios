//
//  OnrampPendingTransactionRecord.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let expressTransactionId: String
    let fromAmount: Decimal
    let fromCurrencyCode: String
    var destinationTokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo
    let provider: ExpressPendingTransactionRecord.Provider
    let date: Date
    let externalTxId: String?
    let externalTxURL: String?

    // Flag for hide transaction from UI. But keep saving in the storage
    var isHidden: Bool
    var transactionStatus: PendingExpressTransactionStatus
}

extension OnrampPendingTransactionRecord: Identifiable {
    var id: String {
        expressTransactionId
    }
}
