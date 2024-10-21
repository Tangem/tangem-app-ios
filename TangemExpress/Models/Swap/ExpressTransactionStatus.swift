//
//  ExpressTransactionStatus.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionStatus: String, Codable {
    case unknown
    case created
    case exchangeTxSent = "exchange-tx-sent"
    case waiting
    case waitingTxHash = "waiting-tx-hash"
    case expired
    case confirming
    case exchanging
    case sending
    case finished
    case failed
    case txFailed = "tx-failed"
    case refunded
    case verifying
    case paused
}
