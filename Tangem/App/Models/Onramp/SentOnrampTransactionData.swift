//
//  SentOnrampTransactionData.swift
//  Tangem
//
//  Created by Aleksei Muraveinik on 20.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SentOnrampTransactionData {
    let txId: String
    let provider: ExpressProvider
    let destinationTokenItem: TokenItem
    let date: Date
    let fromAmount: Decimal
    let fromCurrencyCode: String
    let externalTxId: String
}
