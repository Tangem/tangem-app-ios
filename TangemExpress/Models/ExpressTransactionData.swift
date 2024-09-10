//
//  ExpressTransactionData.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressTransactionData {
    public let requestId: String
    public let fromAmount: Decimal
    public let toAmount: Decimal

    /// The Internal `tangem-express` transaction id
    public let expressTransactionId: String
    public let transactionType: ExpressTransactionType

    /// account for debiting tokens (same as toAddress)
    /// for CEX doesn't matter from which address send
    public let sourceAddress: String?

    /// swap smart-contract address as `spender` or `router`
    /// CEX address for sending transaction
    public let destinationAddress: String

    /// MEMO / DestinationTag or something additional id
    public let extraDestinationId: String?

    /// The value which should be in tx value
    public let txValue: Decimal

    /// The value which should be in tx data. EVM-like blockchains
    public let txData: String?

    /// The value which will be included in value. Used in dex/bridge
    public let otherNativeFee: Decimal?

    /// The estimated gas. WILL NOT use for transaction building
    public let estimatedGasLimit: Int?

    /// CEX provider transaction id
    public let externalTxId: String?
    /// The URL of CEX provider exchange status page
    public let externalTxUrl: String?

    public init(
        requestId: String,
        fromAmount: Decimal,
        toAmount: Decimal,
        expressTransactionId: String,
        transactionType: ExpressTransactionType,
        sourceAddress: String?,
        destinationAddress: String,
        extraDestinationId: String?,
        txValue: Decimal,
        txData: String?,
        otherNativeFee: Decimal?,
        estimatedGasLimit: Int?,
        externalTxId: String?,
        externalTxUrl: String?
    ) {
        self.requestId = requestId
        self.fromAmount = fromAmount
        self.toAmount = toAmount
        self.expressTransactionId = expressTransactionId
        self.transactionType = transactionType
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.extraDestinationId = extraDestinationId
        self.txValue = txValue
        self.txData = txData
        self.otherNativeFee = otherNativeFee
        self.estimatedGasLimit = estimatedGasLimit
        self.externalTxId = externalTxId
        self.externalTxUrl = externalTxUrl
    }
}
