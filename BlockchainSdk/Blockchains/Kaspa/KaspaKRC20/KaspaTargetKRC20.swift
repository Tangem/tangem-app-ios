//
// KaspaTargetKRC20.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 17.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTargetKRC20: TargetType {
    let request: Request
    let baseURL: URL
    
    var path: String {
        switch request {
        case .balance(let address, let token):
            return "krc20/address/\(address)/token/\(token)"
        }
    }
    
    var method: Moya.Method {
        switch request {
        case .balance:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch request {
        case .balance:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}

extension KaspaTargetKRC20 {
    enum Request {
        case balance(address: String, token: String)
    }
}
