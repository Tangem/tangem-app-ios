//
//  VeChainFeeParams.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 27.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainFeeParams: FeeParameters {
    enum TransactionPriority: CaseIterable {
        case low
        case medium
        case high
    }

    let priority: TransactionPriority
    let vmGas: Int
}
