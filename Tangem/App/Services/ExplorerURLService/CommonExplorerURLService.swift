//
//  CommonExplorerURLService.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

struct CommonExplorerURLService {}

extension CommonExplorerURLService: ExplorerURLService {
    func getExplorerURL(for blockchain: SwappingBlockchain, transactionID: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        switch blockchain {
        case .ethereum:
            return factory.makeProvider(for: .ethereum(testnet: false)).url(transaction: transactionID)
        case .bsc:
            return factory.makeProvider(for: .bsc(testnet: false)).url(transaction: transactionID)
        case .polygon:
            return factory.makeProvider(for: .polygon(testnet: false)).url(transaction: transactionID)
        case .avalanche:
            return factory.makeProvider(for: .avalanche(testnet: false)).url(transaction: transactionID)
        case .fantom:
            return factory.makeProvider(for: .fantom(testnet: false)).url(transaction: transactionID)
        case .arbitrum:
            return factory.makeProvider(for: .arbitrum(testnet: false)).url(transaction: transactionID)
        case .gnosis:
            return factory.makeProvider(for: .gnosis).url(transaction: transactionID)
        case .optimism:
            return factory.makeProvider(for: .optimism(testnet: false)).url(transaction: transactionID)
        case .klayth, .aurora:
            return nil
        }
    }
}
