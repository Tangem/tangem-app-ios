//
//  VeChainWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let sdkConfig = input.blockchainSdkConfig
        let networkConfig = input.networkConfig
        let providers: [VeChainNetworkProvider] = APIResolver(blockchain: blockchain, config: sdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                VeChainNetworkProvider(baseURL: nodeInfo.url, configuration: networkConfig)
            }

        let networkService = VeChainNetworkService(
            blockchain: blockchain,
            providers: providers
        )

        let transactionBuilder = VeChainTransactionBuilder(isTestnet: blockchain.isTestnet)

        return VeChainWalletManager(
            wallet: input.wallet,
            networkService: networkService,
            transactionBuilder: transactionBuilder
        )
    }
}
