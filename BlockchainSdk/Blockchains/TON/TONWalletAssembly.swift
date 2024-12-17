//
//  TONWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 17.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TONWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let blockchain = input.blockchain
        let config = input.blockchainSdkConfig

        let providers: [TONProvider] = APIResolver(blockchain: blockchain, config: config)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                TONProvider(node: nodeInfo, networkConfig: input.networkConfig)
            }

        let transactionBuilder = TONTransactionBuilder(wallet: input.wallet)

        return try TONWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: .init(
                providers: providers,
                blockchain: input.blockchain
            )
        )
    }
}
