//
//  VeChainTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct VeChainTarget {
    let baseURL: URL
    let target: Target
}

// MARK: - Auxiliary types

extension VeChainTarget {
    enum Target {
        case viewAccount(address: String)
        case viewBlock(request: VeChainNetworkParams.BlockInfo)
        case callContract(contractCall: VeChainNetworkParams.ContractCall)
        case sendTransaction(rawTransaction: String)
        case transactionStatus(request: VeChainNetworkParams.TransactionStatus)
    }
}

// MARK: - TargetType protocol conformance

extension VeChainTarget: TargetType {
    var path: String {
        switch target {
        case .viewAccount(let address):
            return "/accounts/\(address)"
        case .viewBlock(let request):
            let path: String
            switch request.requestType {
            case .specificWithId(let blockId):
                path = blockId
            case .specificWithNumber(let blockNumber):
                path = String(blockNumber)
            case .latest:
                path = "best"
            case .latestFinalized:
                path = "finalized"
            }
            return "/blocks/\(path)"
        case .callContract:
            return "/accounts/*"
        case .sendTransaction:
            return "/transactions"
        case .transactionStatus(let request):
            return "/transactions/\(request.hash)"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .viewAccount,
             .viewBlock,
             .transactionStatus:
            return .get
        case .sendTransaction,
             .callContract:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch target {
        case .viewAccount,
             .viewBlock:
            return .requestPlain
        case .transactionStatus(let request):
            let parameters = [
                "pending": request.includePending,
                "raw": request.rawOutput,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .callContract(let contractCall):
            return .requestJSONEncodable(contractCall)
        case .sendTransaction(let rawTransaction):
            return .requestJSONEncodable(VeChainNetworkParams.Transaction(raw: rawTransaction))
        }
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
}
