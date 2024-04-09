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

    var isEmpty: Bool {
        switch self {
        case .memo, .destinationTag:
            return false
        case .none:
            return true
        }
    }

    var name: String? {
        switch self {
        case .destinationTag:
            return Localization.sendDestinationTagField
        case .memo:
            return Localization.sendExtrasHintMemo
        case .none:
            return nil
        }
    }

    static func fields(for blockchain: Blockchain) -> SendAdditionalFields {
        switch blockchain {
        case .stellar,
             .binance,
             .ton,
             .cosmos,
             .terraV1,
             .terraV2,
             .algorand,
             .hedera:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
