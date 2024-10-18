//
//  SolanaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Solana_Swift

struct SolanaWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return SolanaWalletManager(wallet: input.wallet).then {
            let endpoints: [RPCEndpoint]
            if input.blockchain.isTestnet {
                endpoints = [
                    .devnetSolana,
                    .devnetGenesysGo,
                ]
            } else {
                let nodeInfoResolver = APINodeInfoResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                endpoints = input.apiInfo.compactMap {
                    if case .solana = $0 {
                        return RPCEndpoint.mainnetBetaSolana
                    }

                    guard
                        let nodeInfo = nodeInfoResolver.resolve(for: $0),
                        var components = URLComponents(url: nodeInfo.url, resolvingAgainstBaseURL: false)
                    else {
                        return nil
                    }

                    components.scheme = SolanaConstants.webSocketScheme
                    guard let urlWebSocket = components.url else {
                        return nil
                    }

                    switch $0 {
                    case .nowNodes:
                        return RPCEndpoint(
                            url: nodeInfo.url,
                            urlWebSocket: urlWebSocket,
                            network: .mainnetBeta,
                            apiKeyHeaderName: nodeInfo.headers?.headerName,
                            apiKeyHeaderValue: nodeInfo.headers?.headerValue
                        )
                    case .quickNode:
                        return RPCEndpoint(
                            url: nodeInfo.url,
                            urlWebSocket: urlWebSocket,
                            network: .mainnetBeta
                        )
                    default:
                        return nil
                    }
                }
            }

            let apiLogger = SolanaApiLoggerUtil()
            let networkRouter = NetworkingRouter(endpoints: endpoints, apiLogger: apiLogger)
            let accountStorage = SolanaDummyAccountStorage()

            $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
            $0.networkService = SolanaNetworkService(solanaSdk: $0.solanaSdk, blockchain: input.blockchain, hostProvider: networkRouter)
        }
    }
}

extension SolanaWalletAssembly {
    enum SolanaConstants {
        static let webSocketScheme = "wss"
    }
}
