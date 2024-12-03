//
//  ChiaAPIResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 16/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(providerType: NetworkProviderType, blockchain: Blockchain) -> NodeInfo? {
        guard case .chia = blockchain else {
            return nil
        }

        let keysInfo = APIKeysInfoProvider(blockchain: blockchain, config: config).apiKeys(for: providerType)
        switch providerType {
        case .tangemChia:
            return .init(url: URL(string: "https://chia.tangem.com")!, keyInfo: keysInfo)
        case .tangemChia3:
            return .init(url: URL(string: "https://chia3.tangem.com")!, keyInfo: keysInfo)
        case .fireAcademy:
            return .init(url: URL(string: "https://kraken.fireacademy.io/leaflet")!, keyInfo: keysInfo)
        default:
            return nil
        }
    }
}
