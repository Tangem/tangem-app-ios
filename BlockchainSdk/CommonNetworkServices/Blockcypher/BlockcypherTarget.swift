//
//  BlockcypherTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockcypherEndpoint {
    case bitcoin(testnet: Bool)
    case ethereum
    case litecoin
    case dogecoin
    case dash

    var path: String {
        var suffix = "main"
        let blockchain: String
        switch self {
        case .bitcoin(let testnet):
            blockchain = "btc"
            if testnet {
                suffix = "test3"
            }
        case .ethereum: blockchain = "eth"
        case .litecoin: blockchain = "ltc"
        case .dogecoin: blockchain = "doge"
        case .dash: blockchain = "dash"
        }
        return "\(blockchain)/\(suffix)"
    }

    var blockchain: Blockchain {
        switch self {
        case .bitcoin(let testnet):
            return .bitcoin(testnet: testnet)
        case .ethereum: return .ethereum(testnet: false)
        case .litecoin: return .litecoin
        case .dogecoin: return .dogecoin
        case .dash: return .dash(testnet: false)
        }
    }
}

struct BlockcypherTarget: TargetType {
    enum BlockcypherTargetType {
        case address(address: String, unspentsOnly: Bool, limit: Int?, isFull: Bool)
        case fee
        case send(txHex: String)
        case txs(txHash: String)
    }

    let endpoint: BlockcypherEndpoint
    let token: String?
    let targetType: BlockcypherTargetType

    var baseURL: URL { URL(string: "https://api.blockcypher.com/v1/\(endpoint.path)")! }

    var path: String {
        switch targetType {
        case .address(let address, _, _, let isFull):
            return "/addrs/\(address)\(isFull ? "/full" : "")"
        case .fee:
            return ""
        case .send:
            return "/txs/push"
        case .txs(let txHash):
            return "/txs/\(txHash)"
        }
    }

    var method: Moya.Method {
        switch targetType {
        case .address, .fee, .txs:
            return .get
        case .send:
            return .post
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        var parameters = token == nil ? [:] : ["token": token!]

        switch targetType {
        case .address(_, let unspentsOnly, let limit, _):
            if unspentsOnly {
                parameters["unspentOnly"] = "true"
            }
            parameters["includeScript"] = "true"
            if let limit = limit {
                parameters["limit"] = "\(limit)"
            }
        case .send(let txHex):
            return .requestCompositeParameters(
                bodyParameters: ["tx": txHex],
                bodyEncoding: JSONEncoding.default,
                urlParameters: parameters
            )
        default:
            break
        }

        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }

    var headers: [String: String]? {
        return nil
    }
}
