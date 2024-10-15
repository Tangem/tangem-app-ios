//
//  EthereumTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct EthereumTarget: TargetType {
    let targetType: EthereumTargetType
    let baseURL: URL
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        EthereumTarget.id += 1
        let request = JSONRPC.Request(id: EthereumTarget.id, method: rpcMethod, params: params)
        return .requestJSONEncodable(request)
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
        ]
    }
}

private extension EthereumTarget {
    static var id: Int = 0

    var rpcMethod: String {
        switch targetType {
        case .balance:
            return "eth_getBalance"
        case .transactions:
            return "eth_getTransactionCount"
        case .pending:
            return "eth_getTransactionCount"
        case .send:
            return "eth_sendRawTransaction"
        case .gasLimit:
            return "eth_estimateGas"
        case .gasPrice:
            return "eth_gasPrice"
        case .priorityFee:
            return "eth_maxPriorityFeePerGas"
        case .call:
            return "eth_call"
        case .feeHistory:
            return "eth_feeHistory"
        }
    }

    // the params have to be nested in an array
    var params: AnyEncodable {
        switch targetType {
        case .balance(let address):
            return AnyEncodable([address, "latest"])
        case .transactions(let address):
            return AnyEncodable([address, "latest"])
        case .pending(let address):
            return AnyEncodable([address, "pending"])
        case .send(let transaction):
            return AnyEncodable([transaction])
        case .gasLimit(let params):
            return AnyEncodable([params])
        case .gasPrice, .priorityFee:
            return AnyEncodable([Int]())  // Empty params
        case .call(let params):
            return AnyEncodable([AnyEncodable(params), AnyEncodable("latest")])
        case .feeHistory:
            // Get fee history for 5 blocks (around a minute) with 25,50,75 percentiles (selected empirically)
            return AnyEncodable([AnyEncodable(5), AnyEncodable("latest"), AnyEncodable([25,50,75])])
        }
    }
}

extension EthereumTarget {
    enum EthereumTargetType {
        case balance(address: String)
        case transactions(address: String)
        case pending(address: String)
        case send(transaction: String)
        case gasLimit(params: GasLimitParams)
        case gasPrice
        case call(params: CallParams)
        case priorityFee

        /// https://www.quicknode.com/docs/ethereum/eth_feeHistory
        case feeHistory
    }
}
