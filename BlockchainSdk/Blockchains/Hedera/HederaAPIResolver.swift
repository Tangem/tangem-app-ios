//
//  HederaAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 16/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .hedera = blockchain else {
            return nil
        }

        let keyInfo = APIKeysInfoProvider(blockchain: blockchain, config: config).apiKeys(for: providerType)
        return .init(
            url: URL(string: "https://pool.arkhia.io/hedera/mainnet/api/v1")!,
            keyInfo: keyInfo
        )
    }
}
