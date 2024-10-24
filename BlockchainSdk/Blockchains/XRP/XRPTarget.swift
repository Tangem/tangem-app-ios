//
//  XRPTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 09.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct XRPTarget: TargetType {
    private let node: NodeInfo
    private let target: XRPTargetType

    var baseURL: URL {
        node.url
    }

    init(node: NodeInfo, target: XRPTargetType) {
        self.node = node
        self.target = target
    }
    
    var path: String {""}
    
    var method: Moya.Method { .post }
    
    var sampleData: Data { return Data() }
    
    var task: Task {
        let parameters: [String: Any]
        switch target {
        case .accountInfo(let account):
            parameters = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "validated"
                    ]
                ]
            ]
        case .unconfirmed(let account):
            parameters = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "current"
                    ]
                ]
            ]
        case .submit(let tx):
            parameters = [
                "method" : "submit",
                "params": [
                    [
                        "tx_blob": tx
                    ]
                ]
            ]
        case .fee:
            parameters = [
                "method" : "fee"
            ]
        case .reserve:
            parameters = [
                "method" : "server_state"
            ]
        }

        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }

        return headers
    }
}

extension XRPTarget {
    enum XRPTargetType {
        case accountInfo(account:String)
        case unconfirmed(account:String)
        case submit(tx:String)
        case fee
        case reserve
    }
}
