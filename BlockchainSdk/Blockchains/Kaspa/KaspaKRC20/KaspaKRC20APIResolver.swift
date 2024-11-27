//
//  KaspaKRC20APIResolver.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 27.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaKRC20APIResolver {
    static var host: String { url.hostOrUnknown }

    private static var url: URL { URL(string: "https://api.kasplex.org/v1")! }

    let config: BlockchainSdkConfig

    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard case .kaspa = blockchain else {
            return nil
        }

        return .init(url: Self.url)
    }
}
