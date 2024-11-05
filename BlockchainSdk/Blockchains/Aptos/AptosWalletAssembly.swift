//
//  AptosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        let chainId: AptosChainId = input.blockchain.isTestnet ? .testnet : .mainnet

        let blockchain = input.blockchain
        let config = input.blockchainSdkConfig
        let networkConfig = input.networkConfig
        let apiResolver = APIResolver(blockchain: blockchain, config: config)
        let providers: [AptosNetworkProvider] = apiResolver.resolveProviders(
            apiInfos: input.apiInfo,
            factory: { nodeInfo, _ in
                AptosNetworkProvider(node: nodeInfo, networkConfig: networkConfig)
            }
        )

        let txBuilder = AptosTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            decimalValue: input.blockchain.decimalValue,
            walletAddress: input.wallet.address,
            chainId: chainId
        )

        let networkService = AptosNetworkService(providers: providers)

        return AptosWalletManager(wallet: input.wallet, transactionBuilder: txBuilder, networkService: networkService)
    }
}
