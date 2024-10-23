//
//  CasperWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CasperWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        FilecoinWalletManager(
            wallet: input.wallet,
            networkService: FilecoinNetworkService(
                providers: APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                    .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                        FilecoinNetworkProvider(
                            node: nodeInfo,
                            configuration: input.networkConfig
                        )
                    }
            ),
            transactionBuilder: try FilecoinTransactionBuilder(publicKey: input.wallet.publicKey)
        )
    }
}
