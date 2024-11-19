//
//  GetBlockBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct GetBlockBlockBookConfig: BlockBookConfig {
    var apiKeyHeaderName: String?
    var apiKeyHeaderValue: String?

    private let credentialsConfig: BlockchainSdkConfig.GetBlockCredentials

    init(_ credentialsConfig: BlockchainSdkConfig.GetBlockCredentials) {
        self.credentialsConfig = credentialsConfig
    }
}

extension GetBlockBlockBookConfig {
    var host: String {
        return "getblock.io"
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        let rpcApiKeyValue = credentialsConfig.credential(for: blockchain, type: .jsonRpc)
        let restNodeApiKeyValue = credentialsConfig.credential(for: blockchain, type: .blockBookRest)

        return BlockBookNode(
            rpcNode: "https://go.\(host)/\(rpcApiKeyValue)",
            restNode: "https://go.\(host)/\(restNodeApiKeyValue)"
        )
    }

    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .fees:
            return "/"
        default:
            return "/api/v2"
        }
    }
}
