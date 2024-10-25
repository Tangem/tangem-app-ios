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
        KaspaWalletManager(wallet: input.wallet).then { walletManager in
            let blockchain = input.blockchain

            walletManager.txBuilder = KaspaTransactionBuilder(blockchain: blockchain)

            let providers = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    KaspaNetworkProvider(
                        url: nodeInfo.url,
                        networkConfiguration: input.networkConfig
                    )
                }

            walletManager.networkService = KaspaNetworkService(providers: providers, blockchain: blockchain)
        }
    }
}
