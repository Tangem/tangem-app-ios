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
    case sell(parameters: PredefinedSellParameters)
}

extension SendType {
    var firstStep: SendStepType {
        switch self {
        case .send: .destination
        case .sell: .summary
        }
    }

    var steps: [SendStepType] {
        switch self {
        case .send:
            return [.destination, .amount, .summary, .fee]
        case .sell:
            return [.summary]
        }
    }

    var predefinedSellParameters: PredefinedSellParameters? {
        switch self {
        case .send:
            return nil
        case .sell(let parameters):
            return parameters
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

    var isSend: Bool {
        switch self {
        case .send:
            return true
        case .sell:
            return false
        }
    }
}

struct PredefinedSellParameters {
    let amount: Decimal
    let destination: String
    let tag: String?
}
