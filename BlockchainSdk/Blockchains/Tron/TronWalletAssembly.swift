//
//  TronWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TronWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return TronWalletManager(wallet: input.wallet).then {
            let config = input.blockchainSdkConfig
            let blockchain = input.blockchain

            let providers: [TronJsonRpcProvider] = APIResolver(blockchain: blockchain, config: config)
                .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                    TronJsonRpcProvider(node: nodeInfo, configuration: input.networkConfig)
                })

            $0.networkService = TronNetworkService(isTestnet: blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder()
        }
    }
}
