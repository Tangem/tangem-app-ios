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
        CasperWalletManager(
            wallet: input.wallet,
            networkService: CasperNetworkService(
                providers: APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                    .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                        CasperNetworkProvider(
                            node: nodeInfo,
                            configuration: input.networkConfig
                        )
                    },
                blockchainDecimalValue: input.blockchain.decimalValue
            ),
            transactionBuilder: CasperTransactionBuilder()
        )
    }
}
