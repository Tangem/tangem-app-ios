//
//  AlephiumWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Alexander Skibin on 17.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let providers: [AlephiumNetworkProvider] = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                AlephiumNetworkProvider(
                    node: nodeInfo,
                    networkConfig: input.networkConfig
                )
            }
        
        return AlephiumWalletManager(
            wallet: input.wallet,
            networkService: AlephiumNetworkService(providers: providers),
            transactionBuilder: AlephiumTransactionBuilder()
        )
    }
}
