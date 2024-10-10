//
//  SubstrateRuntimeVersionProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 20.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SubstrateRuntimeVersionProvider {
    private let network: PolkadotNetwork

    init(network: PolkadotNetwork) {
        self.network = network
    }

    // Use experimentally obtained values, or try running the script in the PolkaParachainMetadataParser folder.
    func runtimeVersion(for meta: PolkadotBlockchainMeta) -> SubstrateRuntimeVersion {
        switch network {
        case .polkadot,
                .westend,
                .kusama:
            // https://github.com/polkadot-fellows/runtimes/releases/tag/v1.2.5
            return meta.specVersion >= 1002005 ? .v15 : .v14
        case .bittensor:
            // 198 is from the first user report
            return meta.specVersion >= 198 ? .v15 : .v14
        case .azero,
                .joystream,
                .energyWebX:
            return .v14
        }
    }
}
