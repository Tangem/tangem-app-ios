//
//  PendingExpressTransaction.swift
//  Tangem
//
//  Created by Andrew Son on 04/12/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransaction: Equatable {
    let transactionRecord: ExpressPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

struct PendingOnrampTransaction: Equatable {
    let transactionRecord: OnrampPendingTransactionRecord
    let statuses: [PendingExpressTransactionStatus]
}

extension PendingOnrampTransaction: Identifiable {
    var id: String {
        transactionRecord.id
    }
}

struct OnrampPendingTransactionRecord: Codable, Equatable {
    let userWalletId: String
    let expressTransactionId: String
    let fromAmount: Decimal?
    let fromCurrencyCode: String
    let destinationTokenTxInfo: ExpressPendingTransactionRecord.TokenTxInfo
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
