//
//  ICPProviderTarget.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ICPProviderTarget: TargetType {
    // MARK: - Properties

    private let node: NodeInfo
    private let requestType: String
    private let canister: String
    private let requestData: Data

    // MARK: - Init

    init(
        node: NodeInfo,
        canister: String,
        requestType: String,
        requestData: Data
    ) {
        self.node = node
        self.canister = canister
        self.requestType = requestType
        self.requestData = requestData
    }

    // MARK: - TargetType

    var baseURL: URL {
        return node.url
    }

    var path: String {
        "api/v2/canister/\(canister)/\(requestType)"
    }

    var method: Moya.Method {
        return .post
    }

    var task: Moya.Task {
        .requestData(requestData)
    }

    var headers: [String: String]? {
        var headers: [String: String] = [
            "Accept": "application/cbor",
            "Content-Type": "application/cbor",
        ]

        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }

        return headers
    }
}
