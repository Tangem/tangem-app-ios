//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct RavencoinTarget {
    let host: String
    let target: Target
}

extension RavencoinTarget: TargetType {
    enum Target {
        case wallet(address: String)
        case utxo(address: String)
        case fees(request: RavencoinFee.Request)
        case transactions(request: RavencoinTransactionHistory.Request)
        case transaction(id: String)
        case send(transaction: RavencoinRawTransaction.Request)
    }

    var baseURL: URL {
        URL(string: host)!
    }

    var path: String {
        switch target {
        case .wallet(let address):
            return "addr/\(address)"
        case .utxo(let address):
            return "addrs/\(address)/utxo"
        case .fees:
            return "utils/estimatesmartfee"
        case .transaction(let id):
            return "tx/\(id)"
        case .send:
            return "tx/send"
        case .transactions:
            return "txs"
        }
    }

    var method: Moya.Method {
        switch target {
        case .send:
            return .post
        case .wallet, .utxo, .transaction, .fees, .transactions:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .fees(let request):
            let parameters = try? request.asDictionary()
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        case .transactions(let request):
            let parameters = try? request.asDictionary()
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        case .send(let transaction):
            return .requestJSONEncodable(transaction)
        case .wallet, .utxo, .transaction:
            return .requestPlain
        }
    }

    // Workaround for API
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 Version/16.1 Safari/605.1.15"]
    }
}
