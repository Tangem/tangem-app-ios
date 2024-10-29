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

    // MARK: - Init

    init(node: NodeInfo) {
        self.node = node
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
        .requestPlain
    }

    var headers: [String: String]?
}

extension CasperTarget {
    enum TargetType {
        case getBalance(address: String)
    }
}
