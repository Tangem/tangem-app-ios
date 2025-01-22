//
//  StakeKitTransaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransaction: Hashable {
    public let id: String
    let amount: Amount
    let fee: Fee
    let unsignedData: String
    public let stepIndex: Int
    let params: StakeKitTransactionParams

    public init(
        id: String,
        amount: Amount,
        fee: Fee,
        unsignedData: String,
        stepIndex: Int,
        params: StakeKitTransactionParams
    ) {
        self.id = id
        self.amount = amount
        self.fee = fee
        self.unsignedData = unsignedData
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
