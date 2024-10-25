//
//  BittensorWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BittensorWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        guard let network = PolkadotNetwork(blockchain: input.blockchain),
              case .bittensor = network else {
            throw WalletError.empty
        }
        
        return PolkadotWalletManager(network: network, wallet: input.wallet).then {
            let runtimeVersionProvider = SubstrateRuntimeVersionProvider(network: network)
            let networkConfig = input.networkConfig
            
            let blockchain = input.blockchain
            let config = input.blockchainSdkConfig
            
            var providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, config: config)
                .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                    PolkadotJsonRpcProvider(node: nodeInfo, configuration: input.networkConfig)
                }
            
            let dwellirResolver = DwellirAPIResolver(config: input.blockchainSdkConfig)
            
            if let dwellirNodeInfo = dwellirResolver.resolve() {
                providers.append(PolkadotJsonRpcProvider(node: dwellirNodeInfo, configuration: networkConfig))
            }
            
            let onfinalityResolver = OnfinalityAPIResolver(config: input.blockchainSdkConfig)
            
            if let onfinalityNodeInfo = onfinalityResolver.resolve() {
                providers.append(PolkadotJsonRpcProvider(node: onfinalityNodeInfo, configuration: networkConfig))
            }
            
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(
                blockchain: input.blockchain,
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                network: network,
                runtimeVersionProvider: runtimeVersionProvider
            )
        }
    }
}
