//
//  PolygonTransactionHistoryTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct PolygonTransactionHistoryTarget {
    let configuration: Configuration
    let target: Target
}

// MARK: - Auxiliary types

extension PolygonTransactionHistoryTarget {
    enum Configuration {
        case polygonScan(isTestnet: Bool, apiKey: String?)
    }

    enum Target {
        case getCoinTransactionHistory(address: String, page: Int, limit: Int)
        case getTokenTransactionHistory(address: String, contract: String, page: Int, limit: Int)
    }
}

// MARK: - TargetType protocol conformance

extension PolygonTransactionHistoryTarget: TargetType {
    var baseURL: URL {
        switch configuration {
        case .polygonScan(let isTestnet, _):
            let endpoint = isTestnet ? "api-testnet" : "api"
            return URL(string: "https://\(endpoint).polygonscan.com")!
        }
    }

    var path: String {
        switch configuration {
        case .polygonScan:
            return "api"
        }
    }

    var method: Moya.Method {
        switch configuration {
        case .polygonScan:
            return .get
        }
    }

    var task: Moya.Task {
        switch configuration {
        case .polygonScan(_, let apiKey):
            var parameters: [String: Any] = [
                "module": "account",
                "startblock": 0,
                "endblock": 99999999,
                "sort": "desc",
            ]
            parameters["apikey"] = apiKey

            switch target {
            case .getCoinTransactionHistory(let address, let page, let limit):
                parameters["action"] = "txlist"
                parameters["address"] = address
                parameters["page"] = page
                parameters["offset"] = limit

                return .requestParameters(
                    parameters: parameters,
                    encoding: URLEncoding.queryString
                )
            case .getTokenTransactionHistory(let address, let contract, let page, let limit):
                parameters["action"] = "tokentx"
                parameters["address"] = address
                parameters["contractaddress"] = contract
                parameters["page"] = page
                parameters["offset"] = limit

                return .requestParameters(
                    parameters: parameters,
                    encoding: URLEncoding.queryString
                )
            }
        }
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
}
