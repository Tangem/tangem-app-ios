//
//  CasperTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct CasperTarget: TargetType {
    // MARK: - Properties

    let node: NodeInfo
    let type: TargetType
    let encoder = JSONEncoder()

    // MARK: - Init

    init(node: NodeInfo, type: TargetType) {
        self.node = node
        self.type = type

        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - TargetType

    var baseURL: URL {
        node.url
    }

    var path: String {
        ""
    }

    var method: Moya.Method {
        .post
    }

    var task: Task {
        CasperTarget.jsonRPCMethodId += 1

        switch type {
        case .getBalance(let data):
            return .requestJSONRPC(
                id: CasperTarget.jsonRPCMethodId,
                method: Method.queryBalance.rawValue,
                params: data,
                encoder: encoder
            )
        case .putDeploy(let data):
            return .requestData(data)
        }
    }

    var headers: [String: String]? {
        switch type {
        case .putDeploy:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}

extension CasperTarget {
    enum TargetType {
        case getBalance(data: CasperNetworkRequest.QueryBalance)
        case putDeploy(data: Data)
    }
}

private extension CasperTarget {
    static var jsonRPCMethodId: Int = 0

    enum Method: String, Encodable {
        case queryBalance = "query_balance"
        case putDeploy = "account_put_deploy"
    }
}
