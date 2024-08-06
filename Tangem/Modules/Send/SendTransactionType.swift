//
//  SendTransactionType.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

enum SendTransactionType {
    case transfer(BSDKTransaction)
    case staking(StakeKitTransaction)
}

extension SendTransactionType {
    var amount: Amount {
        switch self {
        case .staking(let transaction):
            return transaction.amount
        case .transfer(let transaction):
            return transaction.amount
        }
    }

    var fee: Fee {
        switch self {
        case .staking(let transaction):
            return transaction.fee
        case .transfer(let transaction):
            return transaction.fee
        }
    }

    var destinationAddress: String {
        switch self {
        case .staking(let transaction):
            return ""
        case .transfer(let transaction):
            return transaction.destinationAddress
        }
    }
}
