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
    let provider: OnrampProvider
    let destinationTokenItem: TokenItem
    let onrampTransactionData: OnrampRedirectData
    let date: Date
}
