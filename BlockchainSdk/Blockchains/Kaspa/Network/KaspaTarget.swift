//
//  KaspaTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTarget: TargetType {
    let request: Request
    let baseURL: URL

    var path: String {
        switch request {
        case .blueScore:
            return "info/virtual-chain-blue-score"
        case .balance(let address):
            return "addresses/\(address)/balance"
        case .utxos(let address):
            return "addresses/\(address)/utxos"
        case .transactions:
            return "transactions"
        case .transaction(let hash):
            return "transactions/\(hash)"
        case .mass:
            return "transactions/mass"
        case .feeEstimate:
            return "info/fee-estimate"
        }
    }

    var method: Moya.Method {
        switch request {
        case .blueScore, .balance, .utxos, .transaction, .feeEstimate:
            return .get
        case .transactions, .mass:
            return .post
        }
    }

    var task: Moya.Task {
        switch request {
        case .blueScore, .balance, .utxos, .transaction, .feeEstimate:
            return .requestPlain
        case .transactions(let transaction):
            return .requestJSONEncodable(transaction)
        case .mass(let data):
            return .requestJSONEncodable(data)
        }
    }

    var headers: [String: String]? {
        nil
    }
}

extension KaspaTarget {
    enum Request {
        case blueScore
        case balance(address: String)
        case utxos(address: String)
        case transactions(transaction: KaspaTransactionRequest)
        case transaction(hash: String)
        case mass(data: KaspaTransactionData)
        case feeEstimate
    }
}
