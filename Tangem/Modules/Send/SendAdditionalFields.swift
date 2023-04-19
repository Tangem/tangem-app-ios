//
//  SendAdditionalFields.swift
//  Tangem
//
//  Created by Andrew Son on 17/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum SendAdditionalFields {
    case memo
    case destinationTag
    case none

    static func fields(for blockchain: Blockchain) -> SendAdditionalFields {
        switch blockchain {
        case .stellar, .binance, .ton, .cosmos:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
