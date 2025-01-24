//
//  StakeKitTransaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransaction: Hashable {
    public enum Status: String {
        case confirmed = "CONFIRMED" // other statuses are not used, add if necessary
    }

    public enum TransactionType: String {
        case split = "SPLIT" // other types are not used, add if necessary
    }

    public let id: String
    let amount: Amount
    let fee: Fee
    let unsignedData: String
    public let type: TransactionType?
    public let status: Status?
    public let stepIndex: Int
    let params: StakeKitTransactionParams

    public init(
        id: String,
        amount: Amount,
        fee: Fee,
        unsignedData: String,
        type: TransactionType?,
        status: Status?,
        stepIndex: Int,
        params: StakeKitTransactionParams
    ) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
        self.type = type
        self.status = status
        self.stepIndex = stepIndex
        self.params = params
    }
}

public struct StakeKitTransactionSendResult: Hashable {
    public let transaction: StakeKitTransaction
    public let result: TransactionSendResult
}

public struct StakeKitTransactionSendError: Error {
    public let transaction: StakeKitTransaction
    public let error: Error
}

public struct StakeKitTransactionParams: Hashable, TransactionParams {
    let validator: String?
    let solanaBlockhashDate: Date

    public init(validator: String? = nil, solanaBlockhashDate: Date) {
        self.validator = validator
        self.solanaBlockhashDate = solanaBlockhashDate
    }
}
