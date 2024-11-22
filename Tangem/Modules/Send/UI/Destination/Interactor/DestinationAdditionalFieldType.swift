//
//  SendDestinationAdditionalField.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum SendDestinationAdditionalField {
    case notSupported
    case empty(type: SendDestinationAdditionalFieldType)
    case filled(type: SendDestinationAdditionalFieldType, value: String, params: TransactionParams)
}

enum SendDestinationAdditionalFieldType {
    case memo
    case destinationTag

    var name: String {
        switch self {
        case .destinationTag:
            return Localization.sendDestinationTagField
        case .memo:
            return Localization.sendExtrasHintMemo
        }
    }

    static func type(for blockchain: Blockchain) -> SendDestinationAdditionalFieldType? {
        switch blockchain {
        case let value where value.hasMemo:
            return .memo
        case let value where value.hasDestinationTag:
            return .destinationTag
        default:
            return .none
        }
    }
}

extension Blockchain {
    var hasMemo: Bool {
        switch self {
        case .stellar,
             .binance,
             .ton,
             .cosmos,
             .terraV1,
             .terraV2,
             .algorand,
             .hedera,
             .sei,
             .internetComputer,
             .casper:
            true
        default:
            false
        }
    }

    var hasDestinationTag: Bool {
        switch self {
        case .xrp:
            true
        default:
            false
        }
    }
}
