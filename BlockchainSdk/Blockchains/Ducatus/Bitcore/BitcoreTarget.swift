//
//  BitcoreTarget.swift
//  TangemKit
//
//  Created by Alexander Osokin on 03.02.2020.
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya

enum BitcoreTarget: TargetType {
    case balance(address: String)
    case unspents(address: String)
    case send(txHex: String)

    var baseURL: URL {
        return URL(string: "https://ducapi.rocknblock.io/api/DUC/mainnet")!
    }

    var path: String {
        switch self {
        case .balance(let address):
            return "/address/\(address)/balance"
        case .unspents(let address):
            return "/address/\(address)/"
        case .send:
            return "tx/send"
        }
    }

    var method: Moya.Method {
        switch self {
        case .balance, .unspents:
            return .get
        case .send:
            return .post
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .balance:
            return .requestPlain
        case .unspents:
            return .requestParameters(parameters: ["unspent": "true"], encoding: URLEncoding.default)
        case .send(let txHex):
            return .requestParameters(parameters: ["rawTx": [txHex]], encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
