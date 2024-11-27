//
//  KaspaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 21.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct KaspaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let apiResolver = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)

        let providers: [KaspaNetworkProvider] = apiResolver
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                // Skip KRC20 nodes
                if nodeInfo.host.contains(KaspaKRC20APIResolver.host) {
                    return nil
                }

                return KaspaNetworkProvider(
                    url: nodeInfo.url,
                    networkConfiguration: input.networkConfig
                )
            }

        let providersKRC20: [KaspaNetworkProviderKRC20] = apiResolver
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                // Skip Kaspa nodes
                if !nodeInfo.host.contains(KaspaKRC20APIResolver.host) {
                    return nil
                }

                return KaspaNetworkProviderKRC20(
                    url: nodeInfo.url,
                    networkConfiguration: input.networkConfig
                )
            }

        return KaspaWalletManager(
            wallet: input.wallet,
            networkService: KaspaNetworkService(providers: providers, blockchain: blockchain),
            networkServiceKRC20: KaspaNetworkServiceKRC20(providers: providersKRC20, blockchain: blockchain),
            txBuilder: KaspaTransactionBuilder(walletPublicKey: input.wallet.publicKey, blockchain: blockchain),
            dataStorage: input.blockchainSdkDependencies.dataStorage
        )
    }
}
