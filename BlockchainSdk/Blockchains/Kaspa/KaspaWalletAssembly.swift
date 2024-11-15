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
            walletManager.txBuilder = KaspaTransactionBuilder(walletPublicKey: input.wallet.publicKey, blockchain: blockchain)

            let providers = APIResolver(blockchain: blockchain, config: input.blockchainSdkConfig)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    KaspaNetworkProvider(
                        url: nodeInfo.url,
                        networkConfiguration: input.networkConfig
                    )
                }

            let providerKRC20URL = blockchain.isTestnet ? URL("https://tn10api.kasplex.org/v1")! : URL("https://api.kasplex.org/v1/")!
            let providersKRC20 = [
                KaspaNetworkProviderKRC20(
                    url: providerKRC20URL,
                    networkConfiguration: input.networkConfig
                ),
            ]

            walletManager.networkService = KaspaNetworkService(providers: providers, blockchain: blockchain)
            walletManager.networkServiceKRC20 = KaspaNetworkServiceKRC20(providers: providersKRC20, blockchain: blockchain)
            walletManager.dataStorage = input.blockchainSdkDependencies.dataStorage
        }
    }
}
