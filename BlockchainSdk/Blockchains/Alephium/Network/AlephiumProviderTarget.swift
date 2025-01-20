//
//  AlephiumProviderTarget.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 20.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya
import Combine

struct AlephiumProviderTarget: TargetType {
    // MARK: - Properties

    private let node: NodeInfo
    private let targetType: TargetType

    // MARK: - Init

    init(node: NodeInfo, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }

    var baseURL: URL {
        URL(string: "")!
    }

    var path: String {
        switch targetType {
        case .getBalance(let address):
            return "addresses/\(address)/balance"
        case .getUTXO(let address):
            return "addresses/\(address)/utxos"
        case .buildTransaction:
            return "transactions/build"
        case .submitTransaction:
            return "transactions/submit"
        case .transactionStatus:
            return "transactions/status"
        }
    }

    var method: Moya.Method {
        switch targetType {
        case .getBalance, .getUTXO, .transactionStatus:
            return .get
        case .buildTransaction, .submitTransaction:
            return .post
        }
    }

    var task: Moya.Task {
        switch targetType {
        case .getBalance, .getUTXO:
            return .requestPlain
        case .transactionStatus(let txId):
            return .requestParameters(parameters: ["txId": txId], encoding: URLEncoding.default)
        case .buildTransaction(let transfer):
            return .requestJSONEncodable(transfer)
        case .submitTransaction(let transfer):
            return .requestJSONEncodable(transfer)
        }
    }

    var headers: [String: String]? {
        var headers = [
            "Accept": "application/json",
        ]
        
        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }

        return headers
    }
}

extension AlephiumProviderTarget {
    enum TargetType {
        case getBalance(address: String)
        case getUTXO(address: String)
        case buildTransaction(AlephiumNetworkRequest.BuildTransferTx)
        case submitTransaction(AlephiumNetworkRequest.Submit)
        case transactionStatus(txId: String)
    }
}
