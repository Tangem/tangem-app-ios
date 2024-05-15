//
//  SendType.swift
//  Tangem
//
//  Created by Andrey Chukavin on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum SendType {
    case send
    case sell(amount: Amount, destination: String, tag: String?)
}

extension SendType {
    var steps: [SendStep] {
        switch self {
        case .send:
            return [.destination, .amount, .summary, .fee]
        case .sell:
            return [.summary]
        }
    }

    var predefinedAmount: Amount? {
        switch self {
        case .send:
            return nil
        case .sell(let amount, _, _):
            return amount
        }
    }

    var predefinedDestination: String? {
        switch self {
        case .send:
            return nil
        case .sell(_, let destination, _):
            return destination
        }
    }

    var predefinedTag: String? {
        switch self {
        case .send:
            return nil
        case .sell(_, _, let tag):
            return tag
        }
    }

    var canIncludeFeeIntoAmount: Bool {
        switch self {
        case .send:
            return true
        case .sell:
            return false
        }
    }
}
