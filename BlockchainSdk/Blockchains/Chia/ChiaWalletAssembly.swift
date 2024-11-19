//
//  ChiaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let networkConfig = input.networkConfig

        let resolver = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
        let providers: [ChiaNetworkProvider] = resolver.resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
            ChiaNetworkProvider(node: nodeInfo, networkConfig: networkConfig)
        })

        return try ChiaWalletManager(
            wallet: input.wallet,
            networkService: .init(
                providers: providers,
                blockchain: input.blockchain
            ),
            txBuilder: .init(
                isTestnet: input.blockchain.isTestnet,
                walletPublicKey: input.wallet.publicKey.blockchainKey
            )
        )
    }
}
