//
//  ChiaProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ChiaProviderTarget: TargetType {
    // MARK: - Properties
    
    private let node: NodeInfo
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: NodeInfo, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    var baseURL: URL {
        node.url
    }

    var path: String {
        switch targetType {
        case .getCoinRecordsBy:
            return "get_coin_records_by_puzzle_hash"
        case .sendTransaction:
            return "push_tx"
        case .getFeeEstimate:
            return "get_fee_estimate"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Moya.Task {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let jrpcRequest: Dictionary<String, Any>?
        
        switch targetType {
        case .getCoinRecordsBy(let puzzleHashBody):
            jrpcRequest = try? puzzleHashBody.asDictionary(encoder: encoder)
        case .sendTransaction(let body):
            jrpcRequest = try? body.asDictionary(encoder: encoder)
        case .getFeeEstimate(let body):
            jrpcRequest = try? body.asDictionary(encoder: encoder)
        }
        
        return .requestParameters(parameters: jrpcRequest ?? [:], encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        var headers: [String : String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }
        
        return headers
    }
}

extension ChiaProviderTarget {
    enum TargetType {
        case getCoinRecordsBy(puzzleHashBody: ChiaPuzzleHashBody)
        case sendTransaction(body: ChiaTransactionBody)
        case getFeeEstimate(body: ChiaFeeEstimateBody)
    }
}
