//
//  TONAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 16/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TONAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(blockchain: Blockchain) -> NodeInfo? {
        guard case .ton = blockchain else {
            return nil
        }

        return .init(
            url: URL(string: "https://toncenter.com/api/v2")!,
            keyInfo: APIKeysInfoProvider(blockchain: blockchain, config: config).apiKeys(for: .ton)
        )
    }
}
