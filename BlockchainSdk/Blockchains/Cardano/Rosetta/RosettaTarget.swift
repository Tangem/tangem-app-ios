//
//  RosettaTarget.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct RosettaTarget: TargetType {
    enum RosettaTargetType {
        case address(addressBody: RosettaAddressBody)
        case submitTransaction(submitBody: RosettaSubmitBody)
        case coins(addressBody: RosettaAddressBody)
    }
    
    let baseURL: URL
    let target: RosettaTargetType
    
    var path: String {
        switch target {
        case .address:
            return "/account/balance"
        case .submitTransaction:
            return "/construction/submit"
        case .coins:
            return "/account/coins"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .address, .submitTransaction, .coins:
            return .post
        }
    }
    
    var sampleData: Data {
        Data()
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        switch target {
        case .address(let body), .coins(let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        case .submitTransaction(let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}
