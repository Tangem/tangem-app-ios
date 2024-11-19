//
//  PublicAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 07/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PublicAPIResolver {
    let blockchain: Blockchain

    func resolve(for link: String) -> NodeInfo? {
        var linkForURL: String = link

        // We need to remove trailing slash from stellar, because StellarSDK manually adds it
        // when creates request link
        if case .stellar = blockchain {
            linkForURL = removeTrailingSlash(from: linkForURL)
        }

        // We also need to remove trailing slash for EVM, because some JSON RPC nodes didn't work correctly
        // if link has trailing slash
        if blockchain.isEvm {
            linkForURL = removeTrailingSlash(from: linkForURL)
        }

        guard let url = URL(string: linkForURL) else {
            return nil
        }

        return NodeInfo(url: url)
    }

    private func removeTrailingSlash(from link: String) -> String {
        var clearedLink = link
        if clearedLink.hasSuffix("/") {
            clearedLink.removeLast()
        }

        return clearedLink
    }
}
