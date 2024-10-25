//
//  AlgorandIndexProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct AlgorandIndexProviderTarget {
    // MARK: - Properties

    private let node: NodeInfo
    private let targetType: TargetType

    // MARK: - Init

    init(node: NodeInfo, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
}

extension AlgorandIndexProviderTarget {
    enum Provider {
        case fullNode(isTestnet: Bool)
        case nowNodes

        var url: URL {
            switch self {
            case .fullNode(let isTestnet):
                if isTestnet {
                    return URL(string: "https://testnet-idx.algonode.cloud/")!
                } else {
                    return URL(string: "https://mainnet-idx.algonode.cloud/")!
                }
            case .nowNodes:
                return URL(string: "https://algo-index.nownodes.io/")!
            }
        }
    }
}

extension AlgorandIndexProviderTarget: TargetType {
    var baseURL: URL {
        return node.url
    }

    var path: String {
        switch targetType {
        case .getTransactions:
            return "v2/transactions"
        }
    }

    var method: Moya.Method {
        switch targetType {
        case .getTransactions:
            return .get
        }
    }

    var task: Moya.Task {
        switch targetType {
        case .getTransactions(let address, let limit, let next):
            let parameters: [String: Any?] = [
                "address": address,
                "limit": limit,
                "next": next,
            ]

            return .requestParameters(
                parameters: parameters.compactMapValues { $0 },
                encoding: URLEncoding.default
            )
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

extension AlgorandIndexProviderTarget {
    enum TargetType {
        case getTransactions(address: String, limit: Int?, next: String?)
    }
}
