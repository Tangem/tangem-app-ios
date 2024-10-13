//
//  SubscanAPITarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct SubscanAPITarget {
    let isTestnet: Bool
    let encoder: JSONEncoder
    let target: Target
}

// MARK: - Auxiliary types

extension SubscanAPITarget {
    enum Target {
        case getAccountInfo(address: String)
        case getExtrinsicsList(address: String, afterId: Int, page: Int, limit: Int)
        case getExtrinsicInfo(hash: String)
    }
}

// MARK: - TargetType protocol conformance

extension SubscanAPITarget: TargetType {
    var baseURL: URL {
        let domain = isTestnet ? "westend" : "polkadot"

        return URL(string: "https://\(domain).api.subscan.io")!
    }

    var path: String {
        switch target {
        case .getAccountInfo:
            return "api/v2/scan/search"
        case .getExtrinsicsList:
            return "api/v2/scan/extrinsics"
        case .getExtrinsicInfo:
            return "api/scan/extrinsic"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getAccountInfo,
             .getExtrinsicsList,
             .getExtrinsicInfo:
            return .post
        }
    }

    var task: Moya.Task {
        switch target {
        case .getAccountInfo(let address):
            let body = SubscanAPIParams.AccountInfo(key: address)
            return .requestCustomJSONEncodable(body, encoder: encoder)
        case .getExtrinsicsList(let address, let afterId, let page, let limit):
            let body = SubscanAPIParams.ExtrinsicsList(address: address, order: .asc, afterId: afterId, page: page, row: limit)
            return .requestCustomJSONEncodable(body, encoder: encoder)
        case .getExtrinsicInfo(let hash):
            let body = SubscanAPIParams.ExtrinsicInfo(hash: hash)
            return .requestCustomJSONEncodable(body, encoder: encoder)
        }
    }

    var headers: [String: String]? {
        return nil
    }
}
