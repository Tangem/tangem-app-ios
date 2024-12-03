//
//  NetworkProviderAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol NetworkProviderAssemblyInput {
    var blockchain: Blockchain { get }
    var blockchainSdkConfig: BlockchainSdkConfig { get }
    var networkConfig: NetworkProviderConfiguration { get }
    var apiInfo: [NetworkProviderType] { get }
}

struct NetworkProviderAssembly {
    // TODO: Refactor in IOS-6639
    func makeBlockBookUTXOProvider(
        with input: NetworkProviderAssemblyInput,
        for type: BlockBookProviderType
    ) -> BlockBookUTXOProvider {
        switch type {
        case .nowNodes:
            return BlockBookUTXOProvider(
                blockchain: input.blockchain,
                blockBookConfig: NowNodesBlockBookConfig(
                    apiKeyHeaderName: Constants.nowNodesApiKeyHeaderName,
                    apiKeyHeaderValue: input.blockchainSdkConfig.nowNodesApiKey
                ),
                networkConfiguration: input.networkConfig
            )
        case .getBlock:
            return BlockBookUTXOProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(input.blockchainSdkConfig.getBlockCredentials),
                networkConfiguration: input.networkConfig
            )
        }
    }

    // TODO: Refactor in IOS-6639
    func makeBitcoinCashBlockBookUTXOProvider(
        with input: NetworkProviderAssemblyInput,
        for type: BlockBookProviderType,
        bitcoinCashAddressService: BitcoinCashAddressService
    ) -> AnyBitcoinNetworkProvider {
        BitcoinCashBlockBookUTXOProvider(
            blockBookUTXOProvider: makeBlockBookUTXOProvider(
                with: input,
                for: type
            ),
            bitcoinCashAddressService: bitcoinCashAddressService
        ).eraseToAnyBitcoinNetworkProvider()
    }

    // TODO: Refactor in IOS-6639
    func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: NetworkProviderAssemblyInput) -> BlockcypherNetworkProvider {
        BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.blockchainSdkConfig.blockcypherTokens,
            configuration: input.networkConfig
        )
    }

    // TODO: Refactor in IOS-6639
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: NetworkProviderAssemblyInput) -> [AnyBitcoinNetworkProvider] {
        let apiKeys: [String?] = [nil] + input.blockchainSdkConfig.blockchairApiKeys

        return apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, configuration: input.networkConfig)
                .eraseToAnyBitcoinNetworkProvider()
        }
    }

    func makeEthereumJsonRpcProviders(with input: NetworkProviderAssemblyInput) -> [EthereumJsonRpcProvider] {
        return APIResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                EthereumJsonRpcProvider(url: nodeInfo.url, configuration: input.networkConfig)
            }
    }
}

extension NetworkProviderAssembly {
    struct Input: NetworkProviderAssemblyInput {
        let blockchainSdkConfig: BlockchainSdkConfig
        let blockchain: Blockchain
        let apiInfo: [NetworkProviderType]

        var networkConfig: NetworkProviderConfiguration {
            blockchainSdkConfig.networkProviderConfiguration(for: blockchain)
        }
    }
}
