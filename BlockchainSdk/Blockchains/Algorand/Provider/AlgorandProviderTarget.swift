//
//  AlgorandProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AlgorandProviderTarget: TargetType {
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
        case .getAccounts(let address):
            return "v2/accounts/\(address)"
        case .getTransactionParams:
            return "v2/transactions/params"
        case .transaction:
            return "v2/transactions"
        case .getPendingTransaction(let txId):
            return "v2/transactions/pending/\(txId)"
        case .getTransactions:
            return "v2/transactions"
        }
    }

    var method: Moya.Method {
        switch targetType {
        case .getAccounts, .getTransactionParams, .getPendingTransaction:
            return .get
        case .transaction:
            return .post
        case .getTransactions:
            return .get
        }
    }

    var task: Moya.Task {
        switch targetType {
        case .getAccounts, .getTransactionParams, .getPendingTransaction:
            return .requestPlain
        case .transaction(let data):
            return .requestData(data)
        case .getTransactions(let params):
            return .requestParameters(parameters: (try? params.asDictionary()) ?? [:], encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        var headers = [
            "Accept": "application/json",
        ]

        switch targetType {
        case .transaction:
            headers["Content-Type"] = "application/x-binary"
        default:
            headers["Content-Type"] = "application/json"
        }

        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }

        return headers
    }
}

extension AlgorandProviderTarget {
    enum TargetType {
        case getAccounts(address: String)
        case getTransactionParams
        case transaction(trx: Data)
        case getTransactions(params: AlgorandTransactionHistory.Request)
        case getPendingTransaction(txId: String)
    }
}
