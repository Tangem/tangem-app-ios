//
//  ExchangeTransactionDataModel.swift
//  TangemExchange
//
//  Created by Sergey Balashov on 23.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeTransactionDataModel {
    public let sourceCurrency: Currency
    public let sourceBlockchain: ExchangeBlockchain
    public let destinationCurrency: Currency

    public let sourceAddress: String
    public let destinationAddress: String

    /// Tx data which will be used as  etherium data in transaction
    public let txData: Data

    /// Amount which will be swapped in WEI
    public let sourceAmount: Decimal
    public let destinationAmount: Decimal

    /// Value which should be sent in transaction
    public let value: Decimal

    /// The gas limit value depends on the complexity of the transaction
    public let gas: EthereumGasDataModel

    /// Calculated estimated fee
    public var fee: Decimal { gas.fee }

    public init(
        sourceCurrency: Currency,
        sourceBlockchain: ExchangeBlockchain,
        destinationCurrency: Currency,
        sourceAddress: String,
        destinationAddress: String,
        txData: Data,
        sourceAmount: Decimal,
        destinationAmount: Decimal,
        value: Decimal,
        gas: EthereumGasDataModel
    ) {
        self.sourceCurrency = sourceCurrency
        self.sourceBlockchain = sourceBlockchain
        self.destinationCurrency = destinationCurrency
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.txData = txData
        self.sourceAmount = sourceAmount
        self.destinationAmount = destinationAmount
        self.value = value
        self.gas = gas
    }
}
