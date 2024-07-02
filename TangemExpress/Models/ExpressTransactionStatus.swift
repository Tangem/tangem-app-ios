//
//  ExpressTransactionStatus.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 08.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionStatus: String, Codable {
    case new
    case waitingTxHash = "waiting-tx-hash"
    case waiting
    case confirming
    case exchanging
    case sending
    case finished
    case failed
    case refunded
    case verifying
    case expired
    case unknown
}
