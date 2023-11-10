//
//  ExpressTransactionData.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressTransactionData {
    /// The Internal `tangem-express` transaction id
    public let expressTransactionId: String
    public let transactionType: ExpressTransactionType

    /// account for debiting tokens (same as toAddress)
    /// for CEX doesn't matter from which address send
    public let sourceAddress: String

    /// swap smart-contract address as `spender` or `router`
    /// CEX address for sending transaction
    public let destinationAddress: String

    /// The value which should be in tx value
    public let value: Decimal

    /// The value which should be in tx data. EVM-like blockchains
    public let txData: String?

    /// CEX provider transaction id
    public let externalTxId: String?
    /// The URL of CEX provider exchange status page
    public let externalTxUrl: String?
}
