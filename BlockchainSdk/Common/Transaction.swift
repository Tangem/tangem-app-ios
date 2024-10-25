//
//  Transaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionParams {}

public struct Transaction {
    public let amount: Amount
    public internal(set) var fee: Fee
    public internal(set) var sourceAddress: String
    public internal(set) var destinationAddress: String
    public internal(set) var changeAddress: String
    public internal(set) var contractAddress: String?
    public var params: TransactionParams? = nil
    
    public init(
        amount: Amount,
        fee: Fee,
        sourceAddress: String,
        destinationAddress: String,
        changeAddress: String,
        contractAddress: String? = nil,
        params: TransactionParams? = nil
    ) {
        self.amount = amount
        self.fee = fee
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.changeAddress = changeAddress
        self.contractAddress = contractAddress
        self.params = params
    }
    
    func withAmount(_ amount: Amount) -> Transaction {
        Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress,
            contractAddress: contractAddress,
            params: params
        )
    }
}

extension Transaction: Equatable {
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.amount == rhs.amount &&
        lhs.fee == rhs.fee &&
        lhs.sourceAddress == rhs.sourceAddress &&
        lhs.destinationAddress == rhs.destinationAddress &&
        lhs.changeAddress == rhs.changeAddress
    }
}

extension Transaction: ThenProcessable {}
