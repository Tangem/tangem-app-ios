//
//  CardanoWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardanoWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return CardanoWalletManager(wallet: input.wallet).then {
            $0.transactionBuilder = CardanoTransactionBuilder()
            let cardanoResponseMapper = CardanoResponseMapper()
            let networkConfig = input.networkConfig

            let linkResolver = APINodeInfoResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
            let providers: [AnyCardanoNetworkProvider] = input.apiInfo.compactMap {
                guard  let nodeInfo = linkResolver.resolve(for: $0) else {
                    return nil
                }

                switch $0 {
                case .getBlock, .tangemRosetta:
                    return RosettaNetworkProvider(
                        url: nodeInfo.url,
                        configuration: networkConfig,
                        cardanoResponseMapper: cardanoResponseMapper
                    )
                    .eraseToAnyCardanoNetworkProvider()
                case .adalite:
                    return AdaliteNetworkProvider(
                        url: nodeInfo.url,
                        configuration: networkConfig, 
                        cardanoResponseMapper: cardanoResponseMapper
                    ).eraseToAnyCardanoNetworkProvider()
                default:
                    return nil
                }
            }

            $0.networkService = CardanoNetworkService(providers: providers)
        }
    }    
}
