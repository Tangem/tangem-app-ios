//
//  CloreAPIResolver.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 21.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CloreAPIResolver {
    let config: BlockchainSdkConfig

    func resolve(providerType: NetworkProviderType) -> NodeInfo? {
        switch providerType {
        case .clore:
            return .init(url: URL(string: "https://blockbook.clore.ai/")!, keyInfo: nil)
        default:
            return nil
        }
    }
}
