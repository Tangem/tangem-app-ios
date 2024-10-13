//
//  AdaliteTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AdaliteTarget: TargetType {
    enum AdaliteTargetType {
        case address(address: String)
        case unspents(addresses: [String])
        case send(base64EncodedTx: String)
    }

    let baseURL: URL
    let target: AdaliteTargetType

    var path: String {
        switch target {
        case .address(let address):
            return "/api/addresses/summary/\(address)"
        case .unspents:
            return "/api/bulk/addresses/utxo"
        case .send:
            return "/api/v2/txs/signed"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .address:
            return .get
        case .unspents, .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch target {
        case .address:
            return .requestPlain
        case .unspents(let addresses):
            let addrs = "[\(addresses.map{ "\"\($0)\"" }.joined(separator: ","))]"
            let data = addrs.data(using: .utf8) ?? Data()
            return .requestData(data)
        case .send(let base64EncodedTx):
            return .requestParameters(parameters: ["signedTx": base64EncodedTx],
                                      encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var headers = ["Content-Type": "application/json"]
        if case .unspents = target {
            headers["charset"] = "utf-8"
        }
        return headers
    }
}
