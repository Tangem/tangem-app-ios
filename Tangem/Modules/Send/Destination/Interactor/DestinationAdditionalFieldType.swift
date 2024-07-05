//
//  DestinationAdditionalFieldType.swift
//  Tangem
//
//  Created by Sergey Balashov on 19.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum DestinationAdditionalFieldType {
    case notSupported
    case empty(type: SendAdditionalFields)
    case filled(type: SendAdditionalFields, value: String, params: TransactionParams)
}

enum SendAdditionalFields {
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

    static func fields(for blockchain: Blockchain) -> SendAdditionalFields? {
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
