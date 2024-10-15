//
// SuiWalletAssembly.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 28.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> any WalletManager {
        let providers = APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                SuiNetworkProvider(
                    node: nodeInfo,
                    networkConfiguration: input.networkConfig
                )
            }

        let transactionBuilder = try SuiTransactionBuilder(walletAddress: input.wallet.address,
                                                           publicKey: input.wallet.publicKey,
                                                           decimalValue: input.wallet.blockchain.decimalValue)

        return SuiWalletManager(wallet: input.wallet, networkService: SuiNetworkService(providers: providers), transactionBuilder: transactionBuilder)
    }
}
