//
//  CasperTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

// TODO: - https://tangem.atlassian.net/browse/IOS-8316
struct CasperTarget: TargetType {
    // MARK: - Properties

    let node: NodeInfo
    let type: TargetType

    // MARK: - Init

    init(node: NodeInfo, type: TargetType) {
        self.node = node
        self.type = type
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
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        switch type {
        case .getBalance(let data):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: Method.queryBalance.rawValue,
                params: data,
                encoder: encoder
            )
        case .putDeploy(let data):
            return .requestData(data)
        }
    }

    var headers: [String: String]? {
        var headers = [String:String]()

        switch type {
        case .putDeploy:
            headers["Content-Type"] = "application/json"
        default:
            break
        }

        return headers
    }
}

extension CasperTarget {
    enum TargetType {
        case getBalance(data: CasperNetworkRequest.QueryBalance)
        case putDeploy(data: Data)
    }

    enum Method: String, Encodable {
        case queryBalance = "query_balance"
        case putDeploy = "account_put_deploy"
    }
}

private extension CasperTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}
