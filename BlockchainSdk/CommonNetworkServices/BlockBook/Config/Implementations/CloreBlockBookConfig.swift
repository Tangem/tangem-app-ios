//
//  CloreBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 21.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CloreBlockBookConfig: BlockBookConfig {
    let urlNode: URL

    let apiKeyHeaderName: String?
    let apiKeyHeaderValue: String?

    init(urlNode: URL, apiKeyHeaderName: String? = nil, apiKeyHeaderValue: String? = nil) {
        self.urlNode = urlNode
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}

extension CloreBlockBookConfig {
    var host: String {
        return urlNode.host ?? ""
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        guard blockchain == .clore else {
            assertionFailure("Any blockchains does not supported for this blockbook")
            return .init(rpcNode: "", restNode: "")
        }

        return BlockBookNode(
            rpcNode: urlNode.absoluteString,
            restNode: urlNode.absoluteString
        )
    }

    func path(for request: BlockBookTarget.Request) -> String {
        return "api/v2"
    }
}
