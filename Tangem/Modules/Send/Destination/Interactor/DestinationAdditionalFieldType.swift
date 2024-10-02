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
        case .stellar,
             .binance,
             .ton,
             .cosmos,
             .terraV1,
             .terraV2,
             .algorand,
             .hedera,
             .sei,
             .internetComputer:
            return .memo
        case .xrp:
            return .destinationTag
        default:
            return .none
        }
    }
}
