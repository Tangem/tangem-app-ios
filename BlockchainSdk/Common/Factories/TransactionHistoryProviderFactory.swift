//
//  TransactionHistoryProviderFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionHistoryProviderFactory {
    private let config: BlockchainSdkConfig
    private let apiList: APIList

    // MARK: - Init
    
    public init(config: BlockchainSdkConfig, apiList: APIList) {
        self.config = config
        self.apiList = apiList
    }
    
    public func makeProvider(for blockchain: Blockchain) -> TransactionHistoryProvider? {
        // Transaction history is only supported on the mainnet
        guard !blockchain.isTestnet else {
            return nil
        }

        let networkAssembly = NetworkProviderAssembly()
        let input = NetworkProviderAssembly.Input(
            blockchainSdkConfig: config,
            blockchain: blockchain,
            apiInfo: apiList[blockchain.networkId] ?? []
        )

        switch blockchain {
        case .bitcoin,
                .litecoin,
                .dogecoin,
                .dash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: [
                    networkAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock),
                    networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes)
                ],
                mapper: UTXOTransactionHistoryMapper(blockchain: blockchain)
            )
        case .bitcoinCash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: [
                    networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes)
                ],
                mapper: UTXOTransactionHistoryMapper(blockchain: blockchain)
            )
        case .ethereum,
                .ethereumPoW,
                .ethereumClassic,
                .bsc,
                .avalanche,
                .arbitrum:
            return EthereumTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes),
                mapper: EthereumTransactionHistoryMapper(blockchain: blockchain)
            )
        case .tron:
            return TronTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes),
                mapper: TronTransactionHistoryMapper(blockchain: blockchain)
            )
        case .polygon:
            return PolygonTransactionHistoryProvider(
                mapper: PolygonTransactionHistoryMapper(blockchain: blockchain),
                networkConfiguration: input.networkConfig,
                targetConfiguration: .polygonScan(isTestnet: blockchain.isTestnet, apiKey: config.polygonScanApiKey)
            )
        case .algorand(_, let isTestnet):
            let node: NodeInfo
            if isTestnet {
                node = .init(url: AlgorandIndexProviderTarget.Provider.fullNode(isTestnet: isTestnet).url)
            } else {
                let keyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
                node = .init(
                    url: AlgorandIndexProviderTarget.Provider.nowNodes.url,
                    keyInfo: keyInfoProvider.apiKeys(for: .nowNodes)
                )
            }

            return AlgorandTransactionHistoryProvider(
                node: node,
                networkConfig: input.networkConfig,
                mapper: AlgorandTransactionHistoryMapper(blockchain: input.blockchain)
            )
        default:
            return nil
        }
    }
}
